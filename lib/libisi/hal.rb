# Copyright (C) 2007-2010 Logintas AG Switzerland
#
# This file is part of Libisi.
#
# Libisi is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Libisi is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Libisi.  If not, see <http://www.gnu.org/licenses/>.

class Hal
  HAL_PREFIX = "/org/freedesktop/Hal/devices"

  def self.parse_hal
    debughal = false
    udis = {}
    open("|lshal") {|f|
      current_item = nil
      current_udi = nil
      while true
	current = f.readline
	
	$log.debug("Current line is: #{current.inspect}") if debughal
	case current
	when /^udi = \'(.*)\'\s*$/
	  $log.debug("UDI: #{$1}") if debughal
	  current_udi = $1
	  current_item ={}
	when /^\s+(\S+) = \{(.*)\} \(string list\)\s*$/
	# list
	  name = $1
	  $log.debug("Array is: #{$2.inspect}") if debughal
	  current_item[name] = $2.split("', '")	
	  current_item[name][0] = current_item[name][0].sub(/^\'/,"") if current_item[name][0]
	  current_item[name][-1] = current_item[name][-1].sub(/\'$/,"") if current_item[name][-1]
	when /^\s+(\S+) = \'(.*)\'  \(string\)\s*$/
	  # string
	  current_item[$1] = $2
	when /^\s+(\S+) = (false|true)  \(bool\)\s*$/
	  # boolean
	  case $2
	  when "false"
	    current_item[$1] = false
	  when "true"
	    current_item[$1] = true
	  else
	    raise "Unexpected boolean value #{$2}"
	  end
	when /^\s+(\S+) = (\-?\d+)  \(.*\)  \(int\)\s*$/,/^\s+(\S+) = (\d+)  \(.*\)  \(uint64\)\s*$/
	  raise "Convert to integer failed #{$2.to_i.to_s} != #{$2}." if $2.to_i.to_s != $2
	  current_item[$1] = $2.to_i
	when /^\s+(\S+) = (\-?\d+\.\d+) \(.*\) \(double\)\s*$/
	  current_item[$1] = $2.to_f
	when /^\s*$/
	  if current_udi
	    udis["udi"] = current_udi
	    udis[current_udi] = current_item 
	  end
	  current_item = nil
	  current_udi = nil
	when /^Dumping/,/^----/
	when /^Dumped/
	else
	  raise "Unexpected line in lshal #{current.inspect}"
	end
      end
    }
  rescue EOFError
    udis
  end

  def self.list
    parse_hal.map {|udi, hash| Hal.new(udi,hash)}    
  end
    

  attr_accessor :udi, :hash
  def initialize(udi, hash)
    raise "udi is nil" unless udi
    raise "hash is nil for #{udi}" unless hash
    @udi = udi
    @hash = hash
  end

  def parent
    Hal.get_by_udi(hash["info.parent"])
  end

  def volume?
    hash["info.category"] == "volume"
  end
  def partition?
    hash["volume.is_partition"] and hash["volume.is_partition"] == true
  end
  def removable?
    return parent.removable? if partition?
    hash["storage.removable"] or (hash["storage.drive_type"] == "sd_mmc")
  end
  def storage?
    hash["info.category"] == "storage"
  end
  def floppy?
    hash["storage.drive_type"] == "floppy"
  end
  def mountable?
    return true if hash["volume.crypto_luks.clear.backing_volume"]
    (hash["volume.fstype"] or "") != "" or is_luks?
  end
  def mounted?
    if is_luks?
      luks_volume and luks_volume.mounted?
    else
      (hash["volume.is_mounted"] or "") != ""
    end   
  end
  def mounted_readonly?
    hash["volume.is_mounted_read_only"]
  end
  def is_luks?
    hash["volume.fstype"] == "crypto_LUKS"
  end
  def exist?
    reload
    return !hash.nil?
  end

  def mount_point
    return nil unless mounted?
    hash["volume.mount_point"]
  end

  def reload

#    dbus_send("org.freedesktop.Hal.Device.Rescan",
#	      "string:#{$name}","string:","array:string:noexec")

    @hash = Hal.parse_hal[udi]
  end
  def hal_lock
    # DISABLED, because commands do not work
    # DISABLED dbus_send("org.freedesktop.Hal.Device.Lock","string:litkeys")
    begin
      return yield
    ensure
      # DISABLED dbus_send("org.freedesktop.Hal.Device.UnLock")
    end
  end
  def dbus_send_with_password(*arguments)
    cmd = ["dbus-send","--print-reply", "--system","--dest=org.freedesktop.Hal","#{udi}"]
    cmd += arguments
    hal_lock {
      raise "Dbus send error" unless system(*cmd)
    }
    reload
  end
  def dbus_send(*arguments)
    cmd = ["dbus-send","--print-reply", "--system","--dest=org.freedesktop.Hal","#{udi}"]
    cmd += arguments
    if arguments[0].include?("Lock")
      execute_command_popen3(cmd)
    else
      hal_lock {execute_command_popen3(cmd)}
    end
    reload
  end

  # mount a volume
  # usage: hal_volume_mount <volume_id> [<mountpoint name>]
  def mount(name = nil, options = {})
    $log.debug("Mount #{udi} to #{name.inspect}")
    raise "Volume #{block_device.inspect} is not mountable" unless mountable?
    return (luks_volume or luks_setup(options)).mount(name,options) if is_luks?

    name ||= label
    name ||= hash["storage.model"]
    name = name.gsub(/\s/,"_")

    if mounted? 
      raise "already mounted to another mount point #{mount_point.inspect}" if mount_point != "/media/#{name}"
      return
    end

    $log.info("Going to mount under #{name.inspect}")
    raise "Cannot mount with name #{name.inspect}" if name.nil? or name.to_s.strip == ""
    #id = open("|id -u") {|f| f.readlines[0].to_i }
    #"array:string:noexec,uid=#{id}
    mount_options = ((options[:mount_options] or "").split(",") + ["noexec"]).uniq.join(",")
    dbus_send("org.freedesktop.Hal.Device.Volume.Mount",
	      "string:#{$name}","string:","array:string:#{mount_options}")
  end

  # unmount a volume
  def umount; unmount ; end
  def unmount
    if luks_setup?
      ret = luks_volume.unmount
      luks_teardown
      return ret
    end
    raise "Not mounted." unless mounted?
    dbus_send("org.freedesktop.Hal.Device.Volume.Unmount","array:string:")
  end
 
  # LUKS
  # setup a luks volume, given its backingn volume
  def luks_setup(options = {})
    raise "Device is no luksdevice." unless is_luks?
    
    storage_device = parent
    device_name = nil
    partition_no = nil
    if parent.hash["info.category"] == 'storage'
      device_name = "#{parent.hash["info.vendor"]} #{parent.hash["info.product"]}"
      partition_no = hash["volume.partition.number"]
    end

    if device_name and partition_no
      prompt_description = "partition #{partition_no} on \"#{device_name}\" (#{block_device})"
    else
      prompt_description = block_device
    end

    password = (options[:password] or $ui.password("Enter LUKS password for #{prompt_description}"))

    5.times {|t|
      # BUG in HAL. Sometimes the label is not set.
      # Retry with Luks Teardown and Setup again.
      # Reload is not permitted for user.
      dbus_send_with_password("org.freedesktop.Hal.Device.Volume.Crypto.Setup","string:#{password}")
      sleep(t + 1)
      if luks_volume.label != ""
	break
      else
	$log.warn("Luks partition of device #{udi} has no label defined. Probably this is a bug in HAL, Teardown Luks again.")
	dbus_send("org.freedesktop.Hal.Device.Volume.Crypto.Teardown")
      end      
    }
    
    luks_volume
  end
  # teardown a luks volume, given its backing volume
  def luks_teardown
    dbus_send("org.freedesktop.Hal.Device.Volume.Crypto.Teardown")
  end

  def luks_setup?
    !luks_volume.nil?
  end
  def luks_backing_volume
    $log.debug("Looking for backing volume: #{hash["volume.crypto_luks.clear.backing_volume"]}")
    Hal.get_by_udi(hash["volume.crypto_luks.clear.backing_volume"])
  end
  def luks_volume
    Hal.list.select {|h| h.hash["volume.crypto_luks.clear.backing_volume"] == udi}[0]
  end
=begin
  # mount a luks volume given its backing volume
  def luks_mount (name)
    local lUdi=$1
    local lName=$2

    if [ -z "$lUdi" ]; then
      return
      fi
      
      lSetupVolumeUdi=$(hal_luks_get_setup_volume $lUdi)
  
  hal_volume_mount $lSetupVolumeUdi $lName
  lRet=$?
  return $lRet
}

# get the assigned volume in case this luks volume has been set up
# usage: hal_luks_get_setup_volume <luks udi>
def luks_get_setup_volume
   local lUdi=$1

  local lVolumeUdis=$(hal_get_volumes)
  if [ -n "$lVolumeUdis" ]; then
    for lVolumeUdi in $lVolumeUdis; do
      if lshal -l -u $lVolumeUdi | grep -q "volume.crypto_luks.clear.backing_volume.*=.*$lHalPrefix/$lUdi"; then
        echo $lVolumeUdi
        return
      fi
    done
  fi

  # not found
  echo ""
}
=end
  def block_device
    hash["block.device"]
  end
  def storage_device
    hash["block.storage_device"]
  end
  def product
    hash["info.product"]
  end
  def label
    hash["volume.label"]
  end
  def fstype
    hash["volume.fstype"]
  end  
  
  # list volume udis on stdout; one udi per line
  # usage: hal_get_volumes
  def self.get_volumes
    list.select {|h| h.volume? }
  end
  
  # list removable volume udis on stdout; one udi per line
  # usage: hal_get_removable_volumes
  def self.get_removable_volumes
    list.select {|h| h.removable? }
  end

  def self.get_by_udi(udi)
    hash = Hal.parse_hal[udi]
    return nil unless hash
    Hal.new(udi, hash)
  end
  def self.get_by_block_device_name(block_device_name)
    list.select {|h|
      h.block_device == block_device_name
    }[0]
  end
  def self.get_by_label(label)
    list.select {|h| h.label == label}[0]
  end

  def self.get_block_device(block_device_name)
    list.select {|h| h.block_device == block_device_name}[0]
  end
  
  # list floppy storage udis on stdout; one udi per line
  # usage: hal_get_floppies
  def self.get_floppies
    list.select {|h| h.storage? and h.floppy? }
  end

  # check whether a floppy is mounted
  def self.floppy_is_mounted?
    get_floppies.select {|f| f.mounted?}.length > 0
  end

  # check whether a floppy is mounted read-only
  def self.floppy_is_mounted_readonly?
    get_floppies.select {|f| f.mounted? and f.mounted_readonly?}.length > 0
  end
  
  def to_s
    ret =  "#{udi}:\n"
    hash.each {|key, val| ret += "  #{key}: #{val.inspect}\n" }
    ret
  end
end

=begin
# mount a floppy
# usage: hal_floppy_mount <floppy_id> [<mountpoint name>]
hal_floppy_mount () {
  local lUdi=$1
  local lName=$2

  local lVolumeUdi=$(hal_floppy_get_volume $lUdi)
  if [ -z "$lVolumeUdi" ]; then
    # wait for floppy if not yet ready...
    echo -n "floppy not yet ready, waiting "
    for i in $(seq 1 10); do
      echo -n "."
      sleep 1
      lVolumeUdi=$(hal_floppy_get_volume $lUdi)
      if [ -n "$lVolumeUdi" ]; then
        # found, continue
        break
      fi
    done

    if [ -z "$lVolumeUdi" ]; then
      # really not available, nothing to do
      return 0
    fi

    echo " ok."
  fi

  hal_volume_mount $lVolumeUdi $lName
}


# unmount a floppy
# usage: hal_floppy_unmount <floppy_id>
hal_floppy_unmount () {
  local lUdi=$1

  local lVolumeUdi=$(hal_floppy_get_volume $lUdi)
  if [ -z "$lVolumeUdi" ]; then
    # volume not available, nothing to do
    return 0
  fi

  hal_volume_unmount $lVolumeUdi
}

# get the volume of a floppy drive
# usage: hal_floppy_get_volume <storage_udi>
hal_floppy_get_volume () {
  local lUdi=$1

  local lVolumeUdis=$(hal_get_volumes)
  if [ -n "$lVolumeUdis" ]; then
    for lVolumeUdi in $lVolumeUdis; do
      if lshal -l -u $lVolumeUdi | grep -q "info.parent.*=.*$lHalPrefix/$lUdi"; then
        echo $lVolumeUdi
        return
      fi
    done
  fi

  # not found
  echo ""
}


# get the corresponding luks volume to this "setup" volume
# usage: hal_luks_get_luks_volume <setup udi>
hal_luks_get_luks_volume () {
  local lUdi=$1

  local lLuksVolume=$(lshal -u $lUdi -l | grep 'volume.crypto_luks.clear.backing_volume' | sed -e "s/^.*'\(.*\)'.*$/\1/" | sed -e "s!^.*/!!")
  echo $lLuksVolume
}


# show a given volume (for testing)
# usage: hal_volume_show <udi>
hal_volume_show () {
  local lUdi=$1

  lDevice=$(hal_volume_get_device $lUdi)
  lParentUdi=$(hal_get_storage $lUdi)
  lProduct=$(hal_volume_get_product $lUdi)
  lLabel=$(hal_volume_get_label $lUdi)

  if hal_storage_is_removable $lParentUdi; then
    lRemovable="true"
  else
    lRemovable="false"
  fi

  if [ "$lRemovable" != true ]; then
    return
  fi

  if hal_volume_is_mounted $lUdi; then
    lMounted="true"
  else
    lMounted="false"
  fi

  if hal_volume_is_mounted_readonly $lUdi; then
    lReadonly="true"
  else
    lReadonly="false"
  fi



  lMountpoint=$(hal_volume_get_mountpoint $lUdi)
  lFilesystem=$(hal_volume_get_filesystem $lUdi)

  local lLuksSetupVolumeUdi=""
  if [ "$lFilesystem" = "crypto_LUKS" ]; then
    lLuksSetupVolumeUdi=$(hal_luks_get_setup_volume $lUdi)
    if [ -n "$lLuksSetupVolumeUdi" ]; then
      lLuksSetupVolumeDevice=$(hal_volume_get_device $lLuksSetupVolumeUdi)
    fi
  fi

  echo "Product:    $lProduct"
  echo "Device:     $lDevice"
  echo "Label:      $lLabel"
  echo "Mounted:    $lMounted"
  echo "Readonly:   $lReadonly"
  echo "Mountpoint: $lMountpoint"
  echo "Filesystem: $lFilesystem"
  echo "Removable:  $lRemovable"
  echo "Udi:        $lUdi"
  if [ -n "$lLuksSetupVolumeUdi" ]; then
    echo "LUKS:       Setup at $lLuksSetupVolumeDevice ($lLuksSetupVolumeUdi)"
  fi
  echo
}

# show a given floppy (for testing)
# usage: hal_floppy_show <udi>
hal_floppy_show () {
  local lUdi=$1

  lDevice=$(hal_storage_get_device $lUdi)
  lProduct=$(hal_storage_get_product $lUdi)
##  lLabel=$(hal_volume_get_label $lUdi)

  if hal_storage_is_removable $lUdi; then
    lRemovable="true"
  else
    lRemovable="false"
  fi

  if [ "$lRemovable" != true ]; then
    return
  fi

  if hal_floppy_is_mounted $lUdi; then
    lMounted="true"
  else
    lMounted="false"
  fi

  lVolumeUdi=$(hal_floppy_get_volume $lUdi)
  if [ -n "$lVolumeUdi" ]; then
    lMountpoint=$(hal_volume_get_mountpoint $lVolumeUdi)
    lLabel=$(hal_volume_get_label $lVolumeUdi)
  else
    lMountpoint="NOT INSERTED"
    lLabel=""
  fi

  if hal_floppy_is_mounted_readonly $lUdi; then
    lReadonly=true
  else
    lReadonly=false
  fi

  echo "Product: $lProduct"
  echo "Device: $lDevice"
  echo "Label: $lLabel"
  echo "Mounted: $lMounted"
  echo "Readonly: $lReadonly"
  echo "Mountpoint: $lMountpoint"
  echo "Removable: $lRemovable"
  echo "Udi: $lUdi"
  echo "VolumeUdi: $lVolumeUdi"
  echo
}
  
end
=end

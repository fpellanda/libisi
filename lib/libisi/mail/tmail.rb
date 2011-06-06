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

require 'tmail'
require 'libisi/mail/base'
require 'net/smtp'
require 'base64'

# bugfix
module TMail
  module TextUtils
    private
    def random_tag
      @@uniq += 1
      t = Time.now
      sprintf('%x%x_%x%x%d%x',
              t.to_i, t.tv_usec,
              $$, Thread.current.object_id, @@uniq, rand(255))
# was
#              $$, Thread.current.id, @@uniq, rand(255))
    end
  end
end


class TMailMail < BaseMail
  
  def send_mail(recipients, text, options = {})
    mail = TMail::Mail.new()
    mail.date = Time.now
    mail.to = recipients
    mail.from = (options[:from] or self.default_from)    
    mail.subject = (options[:subject] or self.default_subject)
    if (ccs = options[:cc])
      $log.debug("Sending mail cc to #{ccs.inspect}")
      mail.cc = ccs
    end
    
    if (bccs = options[:bcc])
      $log.debug("Sending mail bcc to #{bccs.inspect}")
      mail.bcc = bccs
    end

    mail.mime_version = "1.0"

    text = text.readlines.join("\n") if text.respond_to?(:readlines)
    if text =~ /\<html/
      # for html
      $log.debug("Expecting text has content type html")
      mail.parts.push(create_text_part(text, "html"))
    else
      $log.debug("Expecting text has content type text")
      mail.parts.push(create_text_part(text))
    end

    (options[:attachments] or []).each {|a|
      mail.parts.push(create_attachment(a))
    }

    # this have to be after parts has been added, otherwisse
    # "can't convert nil into String" will be thrown on adding parts
    mail.set_content_type( 'multipart', 'mixed' )
    mail.message_id = TMail.new_message_id(full_qualified_domainname)
    
    Net::SMTP.start("localhost",25) do |smtpclient|
      $log.info("Sending mail with subject #{mail.subject.to_s.inspect} to #{mail.to.to_s.inspect}")
      smtpclient.send_message(mail.to_s, mail.from, mail.to)
    end
  end
  
  def create_text_part(text, content_type = "plain")
    text_part = TMail::Mail.new
    text_part.body = text
    text_part.transfer_encoding = '7bit'
    text_part.set_content_type('text', content_type)
    text_part.charset = 'utf-8'
    text_part
  end

  def create_attachment(file_name)
    file = Pathname.new(file_name)
    raise "File not readable: #{file_name}" unless file.readable?
    $log.info("Creating attachment #{file_name}")
    attachment = TMail::Mail.new
    if file_name =~ /bz2/ or file_name =~ /bzip2/
      attachment.body = Base64.encode64(Pathname.new(file_name).readlines.join)
      file_name = file.basename
    else
      $log.info("Compressing attachment to bz2")
      command = "|cat #{file_name.to_s.inspect} | bzip2"
      $log.debug{"Compression command is: #{command.inspect}"}
      compr = open(command) {|f| f.readlines.join}
      raise "Error compressing attachment." unless $?.success?
      $log.info("Compressed file has length #{compr.length}")
      attachment.body = Base64.encode64(compr)
      file_name = "#{file.basename}.bz2"
    end
    
    $log.debug("Attaching file #{file_name}")
    attachment.transfer_encoding = '7bit'
    attachment.encoding = 'base64'
    attachment.set_content_type('application', 'x-bzip', 'name' => "#{file_name.to_s}")
    attachment.header["Content-Disposition"] = "attachment; filename=#{file_name.to_s}"
    attachment
  end
end

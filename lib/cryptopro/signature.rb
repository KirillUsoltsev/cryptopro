module Cryptopro
  class Signature < Cryptopro::Base
    MESSAGE_FILE_NAME = "message.txt"
    # Должен называться как файл с сообщением, только расширение .sgn
    SIGNATURE_FILE_NAME = "message.txt.sgn"

    # Options: message, signature, certificate
    def self.verify(options)
      raise "Message required" if (options[:message].nil? || options[:message].empty?)
      raise "Signature required" if (options[:signature].nil? || options[:signature].empty?)
      raise "Certificate required" if (options[:certificate].nil? || options[:certificate].empty?)

      # Для работы с cryptcp требуется, чтобы сообщение, полпись и сертификат были в виде файлов
      # Создаётся временная уникальная папка для каждой проверки
      tmp_dir = create_temp_dir
      create_temp_files(tmp_dir, options)
      valid = execute(tmp_dir)
    end

    private

      def self.create_temp_files(tmp_dir, options)
        # Создать файл сообщения
        create_temp_file(tmp_dir, MESSAGE_FILE_NAME, options[:message])
        # Создать файл подписи
        create_temp_file(tmp_dir, SIGNATURE_FILE_NAME, options[:signature])
        # Создать файл сертификата
        certificate_with_container = add_container_to_certificate(options[:certificate])
        create_temp_file(tmp_dir, CERTIFICATE_FILE_NAME, certificate_with_container)
      end

      # Обсуждение формата использования: http://www.cryptopro.ru/forum2/Default.aspx?g=posts&t=1516
      # Пример вызова утилиты cryptcp:
      # cryptcp -vsignf -dir /home/user/signs -f certificate.cer message.txt
      # /home/user/signs -- папка с подписью, имя которой соответствуют имени сообщения, но с расширением .sgn
      def self.execute(dir)
        Cocaine::CommandLine.path = ["/opt/cprocsp/bin/amd64", "/opt/cprocsp/bin/ia32"]
        line = Cocaine::CommandLine.new("cryptcp", "-vsignf -dir :signatures_dir -f :certificate -nochain :message",
          :signatures_dir => dir,
          :certificate => "#{dir}/#{CERTIFICATE_FILE_NAME}",
          :message => "#{dir}/#{MESSAGE_FILE_NAME}"
        )
        begin
          line.run
          true
        rescue Cocaine::ExitStatusError
          false
        rescue Cocaine::CommandNotFoundError => e
          raise "Command cryptcp was not found"
        end
      end

  end
end

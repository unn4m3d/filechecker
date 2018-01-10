require "./filechecker/*"
require "logger"

module FileChecker
  class Checker
    @root : String
    @logger : Logger
    @ignore_extensions : Array(String)

    def initialize(@root, @logger = Logger.new(STDOUT), @ignore_extensions = [] of String)
    end

    private def windows?
      {% if flag? :windows || flag? :win32 %}
        true
      {% else %}
        false
      {% end %}
    end

    def compare(data : Files, **opts)
      files = data.files

      chk = CheckResult.new({} of String => Result)

      Dir.cd @root do
        Dir.glob("**/*") do |entry|
          next if File.directory? entry
          next if @ignore_extensions.includes? File.extname entry

          unless files.has_key? entry
            @logger.debug "#{entry} isn't listed in source data", "FileChecker"
            chk.result[entry] = Result.new FileState::REDUNDANT, nil
            files.delete entry
            next
          end

          if files[entry].size != File.size(entry)
            @logger.debug "#{entry} has invalid size #{File.size(entry)}, not #{files[entry].size}"
            chk.result[entry] = Result.new FileState::CORRUPT, "size"
            files.delete entry
            next
          end

          data = FileData.from_file @root, entry, files[entry].checksums.keys, windows?

          check = true
          data.checksums.each do |k, v|
            unless v == files[entry].checksums[k]
              @logger.debug "#{entry} has invalid #{k} checksum : #{v}, not #{files[entry].checksums[k]}"
              check = false
              chk.result[entry] = Result.new FileState::CORRUPT, k
              files.delete entry
              break
            end
          end
          next unless check

          chk.result[entry] = Result.new FileState::OK, nil unless opts[:diff_only]

          files.delete entry
        end

        files.keys.each do |f|
          @logger.debug "#{f} is missing"
          chk.result[f] = Result.new FileState::MISSING, nil unless @ignore_extensions.includes? File.extname(f)
        end
      end

      chk
    end

    def obtain(digests : Array(String), win_paths = false)
      result = Files.new({} of String => FileData)

      Dir.cd @root do
        Dir.glob("**/*") do |entry|
          next if File.directory? entry
          result.files[entry] = FileData.from_file @root, entry, digests, win_paths unless @ignore_extensions.includes? File.extname(entry)
        end
      end

      result
    end
  end
end

require "json"
require "openssl"

module FileChecker
  class FileData
    JSON.mapping(
      path: String,
      size: UInt64,
      checksums: Hash(String, String)
    )

    def self.checksum(path, algo)
      digest = OpenSSL::Digest.new algo
      bytes = Bytes.new 16384
      File.open(path) do |f|
        while true
          count = f.read bytes
          break if count == 0
          digest.update Bytes.new(bytes.pointer(count), count)
        end
      end
      digest.hexdigest
    end

    def self.from_file(root : String, file : String, digests : Array(String), win_paths = false)
      path = File.expand_path file, root
      size = File.size path
      chk = Hash(String, String).zip(digests, digests.map{ |x| checksum(path, x) })
      if win_paths
        file = file.gsub %r{/}, "\\"
      else
        file = file.gsub %r{\\}, "/"
      end
      new file, size, chk
    end

    def initialize(@path, @size, @checksums)
    end

    def_equals_and_hash path, size, checksums
  end

  class Files
    JSON.mapping(
      files: Hash(String, FileData)
    )

    def initialize(@files)
    end
  end

  enum FileState
    MISSING
    CORRUPT
    REDUNDANT
    OK
  end

  class Result
    JSON.mapping(
      state: FileState,
      reason: { type: String, nilable: true }
    )

    def initialize(@state, @reason)
    end

    def_equals_and_hash state, reason
  end

  class CheckResult
    JSON.mapping(
      result: Hash(String, Result)
    )

    def initialize(@result)
    end
  end
end

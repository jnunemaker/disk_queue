require "simple_uuid"
require "disk_queue/file"

class DiskQueue
  def initialize(directory)
    @directory = directory
  end

  def push(item)
    path = File.join(@directory, generate_file_name)

    File.atomic_write(path) do |file|
      file.write item
    end
  end

  def pop
    dir = Dir.new(@directory)
    dir.read # .
    dir.read # ..

    while first = dir.read
      path = File.join(@directory, first)

      File.open(path, "r") do |file|
        if file.flock(File::LOCK_EX | File::LOCK_NB)
          yield File.read(path)
          File.delete(path)
          return
        end
      end
    end
  ensure
    dir.close
  end

  def generate_file_name
    SimpleUUID::UUID.new.to_guid
  end
end

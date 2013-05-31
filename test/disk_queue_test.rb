require "fileutils"
require "minitest/autorun"
require_relative "../lib/disk_queue"

class DiskQueueTest < Minitest::Test
  attr_reader :directory_name

  def setup
    @directory_name = "/tmp/disk_queue"
    FileUtils.rm_r(directory_name)
    FileUtils.mkdir_p(directory_name)
  end

  def test_push_and_pop
    queue = DiskQueue.new(directory_name)
    queue.push("me first")
    queue.pop { |item| assert_equal "me first", item }
  end

  def test_queue_emptyable
    queue = DiskQueue.new(directory_name)
    queue.push("me first")
    queue.pop { |item| } # drain the queue
    queue.pop { |item| assert_nil item }
  end

  def test_exception_in_pop_block
    queue = DiskQueue.new(directory_name)
    queue.push("me first")

    begin
      queue.pop { |item| raise 'nope' }
    rescue => exception
      queue.pop { |item| assert_equal "me first", item }
    end
  end

  def test_pop_concurrency
    queue = DiskQueue.new(directory_name)
    queue.push("me first")

    queue.pop { |outer_item|
      assert_equal "me first", outer_item
      queue.pop { |inner_item|
        assert_nil inner_item
      }
    }
  end

  def test_cannot_pop_locked_file
    queue = DiskQueue.new(directory_name)
    File.open(File.join(directory_name, "foo"), "w") do |file|
      file.flock(File::LOCK_EX | File::LOCK_NB)
      file.write "1"
      queue.pop { |item| assert_nil item }
    end

    queue.pop { |item| assert_equal "1", item }
  end
end

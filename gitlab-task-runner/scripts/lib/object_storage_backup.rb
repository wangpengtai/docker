require 'open3'
require 'fileutils'

class String
  def red; "\e[31m#{self}\e[0m" end
  def green; "\e[32m#{self}\e[0m" end
  def blue; "\e[34m#{self}\e[0m" end
end

class ObjectStorageBackup
  attr_accessor :name, :local_tar_path, :remote_bucket_name, :tmp_bucket_name

  def initialize(name, local_tar_path, remote_bucket_name, tmp_bucket_name = 'tmp')
    @name = name
    @local_tar_path = local_tar_path
    @remote_bucket_name = remote_bucket_name
    @tmp_bucket_name = tmp_bucket_name
  end

  def backup
    puts "Dumping #{@name} ...".blue

    cmd = %W(s3cmd sync s3://#{@remote_bucket_name} /tmp/#{@name})
    output, status = run_cmd(cmd)
    failure_abort(output) unless status.zero?

    return unless File.exist? "/tmp/#{@name}" # Bucket may be empty
    cmd = %W(tar -czf #{@local_tar_path} -C /tmp/#{@name} . )
    output, status = run_cmd(cmd)
    failure_abort(output) unless status.zero?

    puts "done".green
  end

  def restore
    puts "Restoring #{@name} ...".blue

    backup_existing
    cleanup
    restore_from_backup
    puts "done".green
  end

  def failure_abort(error_message)
    puts "[Error] #{error_message}".red
    abort "Restore #{@name} failed"
  end

  def upload_to_object_storage(source_path)
    # s3cmd treats `-` as a special filename for using stdin, as a result
    # we need a slightly different syntax to support syncing the `-` directory (used for system uploads)
    if File.basename(source_path) == '-'
      cmd = %W(s3cmd sync #{source_path}/ s3://#{@remote_bucket_name}/-/)
    else
      cmd = %W(s3cmd sync #{source_path} s3://#{@remote_bucket_name})
    end

    output, status = run_cmd(cmd)

    failure_abort(output) unless status.zero?
  end

  def run_cmd(cmd)
    _, stdout, wait_thr = Open3.popen2e(*cmd)
    return stdout.read, wait_thr.value.exitstatus
  end

end

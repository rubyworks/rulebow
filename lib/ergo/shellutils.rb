module Osu

  # TODO: Borrow code from Detroit for ShellUtils and beef her up!

  # File system utility methods.
  #
  module ShellUtils
    # Shell out via system call.
    #
    # Arguments
    #   args - Argument vector. [Array]
    #
    # Returns success of shell invocation.
    def sh(*args)
      env = (Hash === args.last ? args.pop : {})
      puts args.join(' ')
      system(env, *args)
    end

    #
    def directory?(path)
      File.directory?(path)
    end

    #
    # Synchronize a destination directory with a source directory.
    #
    # TODO: Augment FileUtils instead.
    # TODO: Not every action needs to be verbose.
    #
    def sync(src, dst, options={})
      src_files = Dir[File.join(src, '**', '*')].map{ |f| f.sub(src+'/', '') }
      dst_files = Dir[File.join(dst, '**', '*')].map{ |f| f.sub(dst+'/', '') }

      removal = dst_files - src_files

      rm_dirs, rm_files = [], []
      removal.each do |f|
        path = File.join(dst, f)
        if File.directory?(path)
          rm_dirs << path
        else
          rm_files << path
        end
      end

      rm_files.each { |f| rm(f) }
      rm_dirs.each  { |d| rmdir(d) }

      src_files.each do |f|
        src_path = File.join(src, f)
        dst_path = File.join(dst, f)
        if File.directory?(src_path)
          mkdir_p(dst_path)
        else
          parent = File.dirname(dst_path) 
          mkdir_p(parent) unless File.directory?(parent)
          install(src_path, dst_path)
        end
      end
    end

    #
    # If FileUtils responds to a missing method, then call it.
    #
    def method_missing(s, *a, &b)
      if FileUtils.respond_to?(s)
        if $DRYRUN
          FileUtils::DryRun.__send__(s, *a, &b)
        else
          FileUtils::Verbose.__send__(s, *a, &b)
        end
      else
        super(s, *a, &b)
      end
    end
  end

end

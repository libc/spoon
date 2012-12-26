require 'spoon'

if RUBY_ENGINE == 'jruby'
  # Taken from Childprocess
  def posix_fileno_for(obj)
    channel = ::JRuby.reference(obj).channel
    begin
      channel.getFDVal
    rescue NoMethodError
      fileno = channel.fd
      if fileno.kind_of?(Java::JavaIo::FileDescriptor)
        fileno = fileno.fd
      end

      fileno == -1 ? obj.fileno : fileno
    end
  rescue
    # fall back
    obj.fileno
  end
else
  def posix_fileno_for(obj)
    obj.fileno
  end
end

r, w = IO.pipe
file_actions = Spoon::FileActions.new
file_actions.close(0)
file_actions.dup2(posix_fileno_for(r), 0)
file_actions.close(posix_fileno_for(w))
spawn_attr = Spoon::SpawnAttributes.new
spawn_attr.pgroup = 0
pid = Spoon.posix_spawn('/usr/bin/env', file_actions, spawn_attr, %w(env ruby))
r.close

w.write "p [$$, Process.getpgrp]\n"
w.close

Process.waitpid(pid)


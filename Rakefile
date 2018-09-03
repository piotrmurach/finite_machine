# encoding: utf-8

require "bundler/gem_tasks"

FileList['tasks/**/*.rake'].each(&method(:import))

jruby = RUBY_ENGINE == 'ruby'
specs = ['spec']
specs << 'spec:perf' if jruby

desc 'Run all specs'
task ci: specs

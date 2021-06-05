# encoding: utf-8

require "bundler/gem_tasks"

FileList['tasks/**/*.rake'].each(&method(:import))

mri = RUBY_ENGINE == 'ruby'
specs = ['spec']
specs.unshift('spec:perf') if mri

desc 'Run all specs'
task ci: specs

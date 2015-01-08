guard :rspec, cmd: 'bundle exec rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/voog/dtk/(.+)\.rb$})     { |m| puts m.inspect;"spec/models/dtk/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { 'spec' }
end


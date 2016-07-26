require 'spec_helper'

# Timezone should be set to UTC
describe command('cmp /etc/localtime /usr/share/zoneinfo/UTC') do
  its(:exit_status) { should eq 0 }
end

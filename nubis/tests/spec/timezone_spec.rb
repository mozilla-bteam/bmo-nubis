require 'spec_helper'

# Timezone should be set to America/Los_Angeles
describe command('cmp /etc/localtime /usr/share/zoneinfo/America/Los_Angeles') do
  its(:exit_status) { should eq 0 }
end

require 'spec_helper'

# These shouldn't start on boot, they are confd enabled/disabled
describe service('httpd') do
  it { should_not be_enabled }
end

describe service('bugzilla-queue') do
  it { should_not be_enabled }
end

describe service('bugzilla-push') do
  it { should_not be_enabled }
end

describe service('supervisord') do
  it { should be_enabled }
end

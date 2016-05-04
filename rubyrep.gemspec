Gem::Specification.new do |s|
  s.name        = 'rubyrep'
  s.version     = '2.1.0'
  s.licenses    = ['MIT']
  s.summary     = 'Asynchronous master-master replication of relational databases.'
  s.description = 'Asynchronous master-master replication of relational databases.'
  s.authors     = ['Arndt Lehmann', 'Kevin Klein']
  s.email       = 'mail@arndtlehman.com'
  s.files       = Dir['Rakefile', '{bin,lib,config,sims,spec,tasks}/**/*', 'README*', 'LICENSE*', 'HISTORY*'] & `git ls-files -z`.split("\0")
  s.homepage    = 'http://rubyrep.org'

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('2.1.0') then
      s.add_runtime_dependency 'activesupport', '~> 4.2', '>= 4.2.5.1'
      s.add_runtime_dependency 'activerecord', '~> 4.2', '>= 4.2.5.1'
      s.add_runtime_dependency(%q<syslogger>, ["~> 1.6"])
      # s.add_development_dependency(%q<hoe>, ["~> 2.10"])
    else
      s.add_dependency(%q<activesupport>, ["~> 4.2.5"])
      s.add_dependency(%q<activerecord>, ["~> 4.2.5"])
      s.add_dependency(%q<syslogger>, ["~> 1.6"])
      # s.add_dependency(%q<hoe>, ["~> 2.10"])
    end
  else
    s.add_dependency(%q<activesupport>, ["~> 4.2.5"])
    s.add_dependency(%q<activerecord>, ["~> 4.2.5"])
    # s.add_dependency(%q<hoe>, ["~> 2.10"])
  end
end

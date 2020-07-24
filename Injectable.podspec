Pod::Spec.new do |s|
  s.name             = 'Injectable'
  s.version          = '0.1.0'
  s.ios.deployment_target = '12.4'
  s.swift_version    = '5'
  s.summary          = 'A lightweight library for easily injecting dependencies and replacing them with test mocks in Swift.'
  s.description      = <<-DESC
Injectable is a protocol-oriented approach to Dependency Injection with no containers, compile-time safety, and no optionals.
With Injectable, no dependency "container" is used. Dependencies are injected manually, giving you complete control over how you write your code.
Injectable enforces dependency resolution at compile time, removing the need for optionals or catching errors.
Replacing your injected objects with mocks for unit testing works like magic!
                       DESC

  s.license  = { :type => 'BSD-3-Clause', :file => 'LICENSE' }
  s.author   = { 'AnthonyMDev' => 'AnthonyMDev@gmail.com' }
  s.source   = { :git => 'https://github.com/forcedotcom/Injectable-Swift.git',
                 :tag => s.version.to_s }
  s.homepage = 'https://github.com/forcedotcom/Injectable-Swift'

  s.static_framework = true

  s.source_files = 'Sources/Injectable/**/*.swift'

  s.test_spec 'Tests' do |ts|
    ts.source_files = 'Tests/InjectableTests/**/*.swift'

    ts.dependency 'Nimble'
  end
  
end

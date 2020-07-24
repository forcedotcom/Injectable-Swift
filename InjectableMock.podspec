Pod::Spec.new do |s|
  s.name             = 'InjectableMock'
  s.version          = '0.1.0'
  s.ios.deployment_target = '12.4'
  s.swift_version    = '5'
  s.summary          = 'A library for injecting mocks for unit testing using the "Injectable" DI Framework.'
  s.description      = <<-DESC
With the Injectable Dependency Injection framework, replacing your injected objects with mocks for unit testing works like magic!
Include the "Injectable" pod in your main target, and the "InjectableMock" pod in your test target to easily replace your injected objects with mocks.
                       DESC

  s.license  = { :type => 'BSD-3-Clause', :file => 'LICENSE' }
  s.author   = { 'AnthonyMDev' => 'anthony.miller@salesforce.com' }
  s.source   = { :git => 'https://github.com/forcedotcom/Injectable-Swift.git',
                 :tag => s.version.to_s }
  s.homepage = 'https://github.com/forcedotcom/Injectable-Swift'

  s.static_framework = true

  s.source_files = 'Sources/InjectableMock/**/*.swift'

  s.framework = 'XCTest'

  s.dependency 'Injectable'
end

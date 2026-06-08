Pod::Spec.new do |s|
  s.name             = 'flutter_face_liveness'
  s.version          = '1.0.0'
  s.summary          = 'Real-time face liveness detection using Google ML Kit.'
  s.description      = <<-DESC
    A production-ready Flutter package for real-time face detection and liveness
    verification using Google ML Kit. Supports eye blink, head movement, and
    anti-spoofing for KYC, attendance, and identity verification.
  DESC
  s.homepage         = 'https://github.com/your-org/flutter_face_liveness'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cerise Tech Solutions' => 'info@cerisetechsolutions.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end

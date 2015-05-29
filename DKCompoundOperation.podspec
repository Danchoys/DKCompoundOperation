Pod::Spec.new do |s|
  s.name             = "DKCompoundOperation"
  s.version          = "0.1.5"
  s.summary          = "Compound operation for use with NSOperationQueue"
  s.homepage         = "https://github.com/danchoys/DKCompoundOperation"
  s.license          = 'MIT'
  s.author           = { "Daniil Konoplev" => "danchoys@icloud.com" }
  s.source           = { :git => "https://github.com/danchoys/DKCompoundOperation.git", :tag => s.version.to_s }
  s.platform     = :ios, '7.0'
  s.requires_arc = true
  s.source_files = 'Pod/Classes/**/*'
end

# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Messenger' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Messenger
  
  # Firebase
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Database'
  pod 'Firebase/Storage'
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  
  # Facebook
  pod 'FBSDKLoginKit'
  
  # Google
  pod 'GoogleSignIn'
  pod 'GoogleUtilities'
  
#  pod 'R.swift'
  pod 'MessageKit'
  pod 'JGProgressHUD'
  pod 'RealmSwift' #cache, mobile database
  pod 'SDWebImage'
  
  pod 'Alamofire'
  
end

post_install do |installer|
 installer.pods_project.targets.each do |target|
  target.build_configurations.each do |config|
   config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
  end
 end
end

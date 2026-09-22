require 'xcodeproj'
project_path = 'sleeptime.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'SleepWidgetExtension' }
if target
  target.remove_from_project
  project.save
  puts "Removed target SleepWidgetExtension"
else
  puts "Target not found"
end

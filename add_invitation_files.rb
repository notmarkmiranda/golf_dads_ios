require 'xcodeproj'

# Open the Xcode project
project_path = 'GolfDads.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target and test target
main_target = project.targets.find { |t| t.name == 'GolfDads' }
test_target = project.targets.find { |t| t.name == 'GolfDadsTests' }

# Get the Models group (should already exist)
models_group = project.main_group['GolfDads']['Models']
test_models_group = project.main_group['GolfDadsTests']['ModelTests']

# Add GroupInvitation.swift to Models group
model_file = models_group.new_file('GolfDads/Models/GroupInvitation.swift')
main_target.source_build_phase.add_file_reference(model_file)

# Add GroupInvitationTests.swift to ModelTests group
test_file = test_models_group.new_file('GolfDadsTests/ModelTests/GroupInvitationTests.swift')
test_target.source_build_phase.add_file_reference(test_file)

# Save the project
project.save

puts "✅ Added GroupInvitation files to Xcode project"

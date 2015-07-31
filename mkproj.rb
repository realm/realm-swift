#!/usr/bin/env ruby

# Create project and workspace for Carthage compatibility.

require 'fileutils'
require 'xcodeproj'

# Configuration
compatibility_name = 'Carthage'
schemes_to_build = ['iOS', 'OSX', 'RealmSwift']
projects_to_build = ['Realm.xcodeproj', 'RealmSwift.xcodeproj']


FileUtils.rm_rf("#{compatibility_name}.xcodeproj")
project = Xcodeproj::Project.new("#{compatibility_name}.xcodeproj")
project.save

schemes_to_build.each do |scheme_name|
	scheme = Xcodeproj::XCScheme.new
	scheme.save_as(project.path, scheme_name)
end

file_refs = projects_to_build.map do |project|
	Xcodeproj::Workspace::FileReference.new(project, 'group')
end

workspace = Xcodeproj::Workspace.new(*file_refs)
workspace.save_as("#{compatibility_name}.xcworkspace")

#!/usr/bin/env ruby
require 'xcodeproj'

##########################
# Example Projects
##########################

class ExampleProject
  attr_accessor :path, :uuids_to_remove, :swift
end

def example_projects

  # RealmSwiftTableViewExample
  realmSwiftTableViewExample = ExampleProject.new
  realmSwiftTableViewExample.swift = true
  realmSwiftTableViewExample.path = "examples/swift/RealmSwiftTableViewExample/RealmSwiftTableViewExample.xcodeproj"
  realmSwiftTableViewExample.uuids_to_remove = [
    "E8C5DD58195025B50055C3B8",
    "E870C959195B32A300163667",
    "E870C95A195B32A300163667",
    "E870C951195B328E00163667",
    "E870C952195B328E00163667",
    "E870C953195B328E00163667",
    "E870C954195B328E00163667",
    "E870C955195B328E00163667",
    "E870C956195B328E00163667",
    "E870C957195B328E00163667",
    "E870C958195B328E00163667",
    "E870C94B195B328E00163667"
  ]

  # RealmSwiftSimpleViewExample
  realmSwiftSimpleExample = ExampleProject.new
  realmSwiftSimpleExample.swift = true
  realmSwiftSimpleExample.path = "examples/swift/RealmSwiftSimpleExample/RealmSwiftSimpleExample.xcodeproj"
  realmSwiftSimpleExample.uuids_to_remove = [
    "4D1E47A8195C1BB40005280D",
    "4D1E47AA195C1BB40005280D",
    "4D1E47AC195C1BB40005280D",
    "4D1E47AE195C1BB40005280D",
    "4D1E47B0195C1BC00005280D",
    "4D1E47A1195C1BB40005280D",
    "4D1E47A2195C1BB40005280D",
    "4D1E47A9195C1BB40005280D",
    "4D1E47AB195C1BB40005280D",
    "4D1E47AD195C1BB40005280D",
    "4D1E47AF195C1BB40005280D",
    "4D1E47B1195C1BC00005280D"
  ]

  # RealmTableViewExample
  realmTableViewExample = ExampleProject.new
  realmTableViewExample.swift = false
  realmTableViewExample.path = "examples/objc/RealmTableViewExample/RealmTableViewExample.xcodeproj"
  realmTableViewExample.uuids_to_remove = [
    "E8F1902F1964C24100B0F161",
    "E8F190311964C24100B0F161",
    "E8F190331964C24100B0F161",
    "E8F190351964C24100B0F161",
    "E8F190371964C24700B0F161",
    "E8F190271964C24100B0F161",
    "E8F190281964C24100B0F161",
    "E8F190301964C24100B0F161",
    "E8F190321964C24100B0F161",
    "E8F190341964C24100B0F161",
    "E8F190361964C24100B0F161",
    "E8F190381964C24700B0F161"
  ]

  # Return all example projects
  [
    realmSwiftTableViewExample,
    realmSwiftSimpleExample,
    realmTableViewExample
  ]
end

##########################
# Functions
##########################

def remove_uuids_from_example(example)
  project = Xcodeproj::Project.open(example.path)

  objects_to_remove = project.objects.select { |o| example.uuids_to_remove.include?(o.uuid) }

  objects_to_remove.each do |object|
    object.remove_from_project
  end

  project.save
end

def add_framework_file_reference(example)
  project = Xcodeproj::Project.open(example.path)
  
  obj = project.new(Xcodeproj::Project::PBXFileReference)
  obj.path = "../../Realm.framework"
  obj.name = "Realm.framework"
  project.main_group << obj

  project.save
end

def add_framework(example)
  project = Xcodeproj::Project.open(example.path)
  
  # Add file reference
  obj = project.new(Xcodeproj::Project::PBXFileReference)
  obj.path = "../../Realm.framework"
  obj.name = "Realm.framework"
  project.main_group << obj

  target = project.targets.first

  # Add to copy build phase
  target.resources_build_phase.add_file_reference(obj)

  # Add to frameworks build phase
  target.frameworks_build_phase.add_file_reference(obj)

  project.save
end

##########################
# Script
##########################

example_projects.each do |example|
  remove_uuids_from_example(example)
  if example.swift
    add_framework(example)
  else
    filepath = example.path + "/project.pbxproj"
    contents = File.read(filepath)
    File.open(filepath, "w") do |file|
      file.puts contents.gsub("../../../build/$(CONFIGURATION)", "../../")
    end
  end
end

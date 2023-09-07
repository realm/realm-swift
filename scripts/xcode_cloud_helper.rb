#!/usr/bin/env ruby
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require "base64"
require "jwt"
require_relative "pr-ci-matrix"

include WORKFLOWS

def usage()
    puts <<~END
    Usage: ruby #{__FILE__} -list-workflows
    Usage: ruby #{__FILE__} -list-products
    Usage: ruby #{__FILE__} -list-repositories
    Usage: ruby #{__FILE__} -list-mac-versions
    Usage: ruby #{__FILE__} -list-xcode-versions
    Usage: ruby #{__FILE__} -workflow [workflow_id]
    Usage: ruby #{__FILE__} -create [workflow_id]
    Usage: ruby #{__FILE__} -delete [workflow_id]
    Usage: ruby #{__FILE__} -build [workflow_id]
    Usage: ruby #{__FILE__} -create-new
    Usage: ruby #{__FILE__} -clear-unused

    environment variables:
    ISSUER_ID: Issuer Id from the App connect APIKey.
    KEY_ID: Key Id from the App connect APIKey.
    PK_PATH: Path to the `.p8` file containing the private key from the App connect APIKey.
    PRODUCT_ID: The product Id parent for all the workflows.
    REPOSITORY_ID: The repository Id pointing `realm-swift` repository.
    TEAM_ID: Team id used for XCode cloud.
    END
    exit 1
end

# Apple App Connect credentials
ISSUER_ID = ENV["ISSUER_ID"]
KEY_ID = ENV["KEY_ID"]
PK_PATH = ENV["PK_PATH"]

# XCode Cloud information
PRODUCT_ID = ENV["PRODUCT_ID"]
REPOSITORY_ID = ENV["REPOSITORY_ID"]
TEAM_ID = ENV["TEAM_ID"]

APP_STORE_URL="https://api.appstoreconnect.apple.com/v1"

def get_jwt_bearer
    private_key = OpenSSL::PKey.read(File.read(PK_PATH))
    info = {
        iss: ISSUER_ID,
        exp: Time.now.to_i + 10 * 60,
        aud: "appstoreconnect-v1"
    }
    header_fields = { kid: KEY_ID }
    token = JWT.encode(info, private_key, "ES256", header_fields)
    return token
end

def get_workflows
    response = get("/ciProducts/#{PRODUCT_ID}/workflows?limit=200")
    result = JSON.parse(response.body)
    list_workflows = []
    result.collect do |doc|
        doc[1].each { |workflow|
            if workflow.class == Hash
                name = workflow["attributes"]["name"].partition('_').first
                version = workflow["attributes"]["name"].partition('_').last
                list_workflows.append({ "workflow" => workflow["attributes"]["name"], "id" => workflow["id"], "target" => name, "version" => version })
            end
        }
    end
    return list_workflows
end

def get_products
    response = get("/ciProducts")
    result = JSON.parse(response.body)
    list_products = []
    result.collect do |doc|
        doc[1].each { |prod|
            if prod.class == Hash
                list_products.append({ "product" => prod["attributes"]["name"], "id" => prod["id"], "type" => prod["attributes"]["productType"] })
            end
        }
    end
    return list_products
end

def get_repositories
    response = get("/scmRepositories")
    result = JSON.parse(response.body)
    list_repositories = []
    result.collect do |doc|
        doc[1].each { |repo|
            if repo.class == Hash
                list_repositories.append({ "name" => repo["attributes"]["repositoryName"], "id" => repo["id"], "url" => repo["attributes"]["httpCloneUrl"] })
            end
        }
    end
    return list_repositories
end

def get_macos_versions
    response = get("/ciMacOsVersions")
    result = JSON.parse(response.body)
    list_macosversion = []
    result.collect do |doc|
        doc[1].each { |macos|
            if macos.class == Hash
                list_macosversion.append({ "name" => macos["attributes"]["name"], "id" => macos["id"], "version" => macos["attributes"]["version"] })
            end
        }
    end
    return list_macosversion
end

def get_xcode_versions
    response = get("/ciXcodeVersions")
    result = JSON.parse(response.body)
    list_xcodeversion = []
    result.collect do |doc|
        doc[1].each { |xcode|
            if xcode.class == Hash
                list_xcodeversion.append({ "name" =>  xcode["attributes"]["name"], "id" => xcode["id"], "version" => xcode["attributes"]["version"] })
            end
        }
    end
    return list_xcodeversion
end

def get_workflow_info(id)
    response = get("/ciWorkflows/#{id}")
    puts "Workflow Info:"
    puts response.body
end

def get(path)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = "Bearer #{JWT_BEARER}"
    request["Accept"] = "application/json"
    response = http.request(request)

    if response.code == "200"
        return response
    else
        puts "ERROR!!! #{response.code} #{response.body}"
    end
end

def create_workflow(name, xcode_version)
    url = "#{APP_STORE_URL}/ciWorkflows"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{JWT_BEARER}"
    request["Content-type"] = "application/json"
    body = create_workflow_request(name, xcode_version)
    request.body = body.to_json
    response = http.request(request)
    if response.code == "201"
        result = JSON.parse(response.body)
        id = result["data"]["id"]
        puts "Worfklow created id: #{id} target: #{name} xcode version: #{xcode_version}"
        puts "https://appstoreconnect.apple.com/teams/#{TEAM_ID}/frameworks/#{PRODUCT_ID}/workflows/#{id}"
        return id
    else
        puts "ERROR!!! #{response.code} #{response.body}"
    end
end

def create_workflow_request(name, xcode_version)
    build_action =
    [{
        "name" => "Build - macOS",
        "actionType" => "BUILD",
        "destination" => "ANY_MAC",
        "buildDistributionAudience" => nil,
        "testConfiguration" => nil,
        "scheme" => "CI",
        "platform" => "MACOS",
        "isRequiredToPass" => true
    }]
    pull_request_start_condition =
    {
        "source" => { "isAllMatch" => true, "patterns" => [] },
        "destination" => { "isAllMatch" => true, "patterns" => [] },
        "autoCancel" => true
    }
    attributes =
    {
        "name" => name,
        "description" => name,
        "isLockedForEditing" => false,
        "containerFilePath" => "Realm.xcodeproj",
        "isEnabled" => false,
        "clean" => false,
        "pullRequestStartCondition" => pull_request_start_condition,
        "actions" => build_action
    }
    xcode_version_id = get_xcode_id(xcode_version)
    mac_os_id = get_macos_latest_release(xcode_version_id)
    relationships =
    {
        "xcodeVersion" => { "data" => { "type" => "ciXcodeVersions", "id" => xcode_version_id }},
        "macOsVersion" => { "data" => { "type" => "ciMacOsVersions", "id" => mac_os_id }},
        "product" => { "data" => { "type" => "ciProducts", "id" => PRODUCT_ID }},
        "repository" => { "data" => { "type" => "scmRepositories", "id" => REPOSITORY_ID }}
    }
    data =
    {
        "type" => "ciWorkflows",
        "attributes" => attributes,
        "relationships" => relationships
    }
    body = { "data" => data }
    return body
end

def get_xcode_id(version)
    list_xcodeversion = get_xcode_versions
    list_xcodeversion.each do |xcode|
        if xcode["name"].include? version
            return xcode["id"]
        end
    end
end

def get_macos_latest_release(xcodeVersionId)
    list_macosversion = get_macos_versionsForXCodeVersion(xcodeVersionId)
    list_macosversion.each do |mac_os, id|
        if mac_os.include? "Latest Release"
            return id
        end
    end
end

def update_workflow(id)
    url = "#{APP_STORE_URL}/ciWorkflows/#{id}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Patch.new(uri)
    request["Authorization"] = "Bearer #{JWT_BEARER}"
    request["Content-type"] = "application/json"
    data =
    {
        "type" => "ciWorkflows",
        "attributes" => { "isEnabled" => true },
        "id" => id
    }
    body = { "data" => data }
    request.body = body.to_json
    response = http.request(request)
    if response.code == "201"
        result = JSON.parse(response.body)
        id = result["data"]["id"]
        puts "Worfklow updated #{id}"
        return id
    else
        puts "ERROR!!! #{response.code} #{response.body}"
    end
end

def delete_workflow(id)
    url = "#{APP_STORE_URL}/ciWorkflows/#{id}"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Delete.new(uri)
    request["Authorization"] = "Bearer #{JWT_BEARER}"
    request["Content-type"] = "application/json"
    response = http.request(request)
    if response.code == "204"
        puts "Workflow deleted #{id}"
    else
        puts "ERROR!!! #{response.code} #{response.body}"
    end
end

def start_build(id)
    url = "#{APP_STORE_URL}/ciBuildRuns"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{JWT_BEARER}"
    request["Content-type"] = "application/json"
    data =
    {
        "type" => "ciBuildRuns",
        "attributes" => {},
        "relationships" => { "workflow" => { "data" => { "type" => "ciWorkflows", "id" => id }}}
    }
    body = { "data" => data }
    request.body = body.to_json
    response = http.request(request)
    if response.code == "201"
        result = JSON.parse(response.body)
        id = result["data"]["id"]
        puts "Workflow build started with id: #{id}:"
        puts response.body
        return id
    else
        puts "ERROR!!! #{response.code} #{response.body}"
    end
end

def get_macos_versions_for_xcode_version(version)
    url = "#{APP_STORE_URL}/ciXcodeVersions/#{version}/macOsVersions"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Authorization"] = "Bearer #{JWT_BEARER}"
    request["Accept"] = "application/json"
    response = http.request(request)

    if response.code == "200"
        result = JSON.parse(response.body)

        list_macosversion = {}
        result.collect do |doc|
            doc[1].each { |macos|
                if macos.class == Hash
                    name = macos["attributes"]["name"]
                    id = macos["id"]
                    list_macosversion.store(name, id)
                end
            }
        end
        return list_macosversion
    else
        puts "ERROR!!! #{response.code} #{response.body}"
    end
end

def create_new_workflows
    print "Are you sure you want to create this workflows?, this will create declared local workflows that may not currently working in other PRs [Y/N]\n"

    user_input = STDIN.gets.chomp.downcase
    if user_input == "y"
        workflows_to_create = []
        current_workflows = get_workflows().map { |workflow| { "target" => workflow["target"], "version" => workflow["version"] }}
        WORKFLOWS::TARGETS.each { |name, filter|
            WORKFLOWS::XCODE_VERSIONS.each { |version|
                if filter.call(version)
                    workflow = { "target" => name, "version" => version }
                    unless current_workflows.include? workflow
                        workflows_to_create.append(workflow)
                    end
                end
            }
        }

        workflows_to_create.each { |workflow|
            name = workflow['target']
            version = workflow['version']
            create_workflow("#{name}_#{version}", version)
        }
    else
        puts "No"
    end
end

def delete_unused_workflows
    print "Are you sure you want to clear unused workflow?, this will delete not-declared local workflows that may be currently working in other PRs [Y/N]\n"

    user_input = STDIN.gets.chomp.downcase
    if user_input == "y"
        local_workflows = []
        WORKFLOWS::TARGETS.each { |name, filter|
            WORKFLOWS::XCODE_VERSIONS.each { |version|
                if filter.call(version)
                    local_workflows.append("#{name}_#{version}")
                end
            }
        }

        remote_workflows = get_workflows
        remote_workflows.each { |workflow|
            unless local_workflows.include? workflow["workflow"]
                puts "#{workflow["id"]} #{workflow["target"]}_#{workflow["version"]}"
                delete_workflow(workflow["id"])
            end
        }
    else
        puts "No"
    end
end

JWT_BEARER = get_jwt_bearer()
if ARGV[0] == '-list-workflows'
    puts get_workflows
elsif ARGV[0] == '-list-products'
    puts get_products
elsif ARGV[0] == '-list-repositories'
    puts get_repositories
elsif ARGV[0] == '-list-mac-versions'
    puts get_macos_versions
elsif ARGV[0] == '-list-xcode-versions'
    puts get_xcode_versions
elsif ARGV[0] == '-workflow'
    get_workflow_info(ARGV[1])
elsif ARGV[0] == '-create'
    create_workflow(ARGV[1], ARGV[2])
elsif ARGV[0] == '-delete'
    deleteWorkflow(ARGV[1])
elsif ARGV[0] == '-build'
    start_build(ARGV[1])
elsif ARGV[0] == '-create-new'
    create_new_workflows
elsif ARGV[0] == '-clear-unused'
    delete_unused_workflows
else
    puts "Error, needs an argument"
end

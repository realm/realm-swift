#!/usr/bin/env ruby
require 'net/http'
require 'net/https'
require 'uri'
require 'json'
require "base64"
require "jwt"
require_relative "pr-ci-matrix"
require 'getoptlong'

include WORKFLOWS

JWT_BEARER = ''
TEAM_ID = ''
$product_id = ''
$repository_id = ''
$xcode_list = ''
$mac_dict = Hash.new
$workflows_list = ''

def usage()
    puts <<~END
    Usage: ruby #{__FILE__} --list-workflows --token [token]
    Usage: ruby #{__FILE__} --list-products --token [token]
    Usage: ruby #{__FILE__} --list-repositories --token [token]
    Usage: ruby #{__FILE__} --list-mac-versions --token [token]
    Usage: ruby #{__FILE__} --list-xcode-versions --token [token]
    Usage: ruby #{__FILE__} --info-workflow [workflow_id] --token [token]
    Usage: ruby #{__FILE__} --create-workflow [name] --xcode-version [xcode_version] --token [token]
    Usage: ruby #{__FILE__} --delete-workflow [workflow_id] --token [token]
    Usage: ruby #{__FILE__} --build-workflow [workflow_id] --token [token]
    Usage: ruby #{__FILE__} --update-workflows --token [token]
    Usage: ruby #{__FILE__} --clear-unused-workflows --token [token]
    Usage: ruby #{__FILE__} --get-token --issuer-id [issuer_id] --key-id [key_id] --pk_path [pk_path]

    environment variables:
    END
    exit 1
end

APP_STORE_URL="https://api.appstoreconnect.apple.com/v1"

def get_jwt_bearer(issuer_id, key_id, pk_path)
    private_key = OpenSSL::PKey.read(File.read(pk_path))
    info = {
        iss: issuer_id,
        exp: Time.now.to_i + 10 * 60,
        aud: "appstoreconnect-v1"
    }
    header_fields = { kid: key_id }
    token = JWT.encode(info, private_key, "ES256", header_fields)
    puts "Token -> #{token}"
end

def get_workflows
    product_id = get_realm_product_id
    response = get("/ciProducts/#{product_id}/workflows?limit=200")
    result = JSON.parse(response.body)
    list_workflows = []
    result.collect do |doc|
        doc[1].each { |workflow|
            if workflow.class == Hash
                list_workflows.append(workflow)
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

def print_workflow_info(id)
    workflow_info = get_workflow_info(id)
    puts "Workflow Info:"
    puts workflow_info
end

def get_workflow_info(id)
    response = get("/ciWorkflows/#{id}")
    return response.body
end

def get(path)
    url = "#{APP_STORE_URL}#{path}"
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
        product_id = get_realm_product_id
        puts "https://appstoreconnect.apple.com/teams/#{TEAM_ID}/frameworks/#{product_id}/workflows/#{id}"
        return id
    else
        puts "ERROR!!! #{response.code} #{response.body}"
    end
end

def create_workflow_request(name, xcode_version)
    build_action = get_action_for_target(name)
    pull_request_start_condition =
    {
        "source" => { "isAllMatch" => true, "patterns" => [] },
        "destination" => { "isAllMatch" => true, "patterns" => [] },
        "autoCancel" => true
    }
    attributes =
    {
        "name" => "#{name}_#{xcode_version}",
        "description" => 'Create by Github Action Update XCode Cloud Workflows',
        "isLockedForEditing" => false,
        "containerFilePath" => "Realm.xcodeproj",
        "isEnabled" => true,
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
        "product" => { "data" => { "type" => "ciProducts", "id" => get_realm_product_id }},
        "repository" => { "data" => { "type" => "scmRepositories", "id" => get_realm_repository_id }}
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
    if !ENV.include?('CI')
        print "Are you sure you want to create this workflows?, this will create declared local workflows that may not currently working in other PRs [Y/N]\n"
        user_input = STDIN.gets.chomp.downcase
    else 
        user_input = 'y'
    end

    if user_input == "y"
        workflows_to_create = []
        current_workflows = get_workflows().map { |workflow| 
            name = workflow["attributes"]["name"].partition('_').first
            version = workflow["attributes"]["name"].partition('_').last
            { "target" => name, "version" => version }
        }
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
            workflow_id = create_workflow(name, version)
            update_workflow(workflow_id)
        }
    else
        puts "No"
    end
end

def delete_unused_workflows
    if !ENV.include?('CI')
        print "Are you sure you want to clear unused workflow?, this will delete not-declared local workflows that may be currently working in other PRs [Y/N]\n"
        user_input = STDIN.gets.chomp.downcase
    else 
        user_input = 'y'
    end
    
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
        remote_workflows.each.map { |workflow| 
            if workflow["attributes"]["name"].include? "Cocoa-prepare"
                return nil
            end

            name = workflow["name"]
            unless local_workflows.include? name
                puts "#{workflow["id"]} #{name}"
                #delete_workflow(workflow["id"])
            end
        }
    else
        puts "No"
    end
end

def get_action_for_target(name)
    workflow_id = get_workflow_id_for_name(name)
    if workflow_id.nil? 
        get_new_action_for_target(name)
    else
        workflow_info = get_workflow_info(workflow_id)
        result = JSON.parse(workflow_info)
        build_action = result["data"]["attributes"]["actions"]
        return build_action
    end
end 

def get_new_action_for_target(name)
    name_split = name.split('_')
    platform = name_split[0]
    scheme = name_split[1]

    name = ''
    platform = ''
    test_destination = ''
    case platform
    when 'catalyst'
        build_action = {
        name = 'Test - macOS (Catalyst)'
        platform = 'MACOS'
        test_destination = {
            "deviceTypeName" => "Mac (Mac Catalyst)",
            "deviceTypeIdentifier" => "mac_catalyst",
            "runtimeName" => "Same As Selected macOS Version",
            "runtimeIdentifier" => "builder",
            "kind" => "MAC"
        }
    when 'ios'
        name = 'Test - iOS'
        platform = 'IOS'
        test_destination =  {
            "deviceTypeName" => "iPhone 11",
            "deviceTypeIdentifier" => "com.apple.CoreSimulator.SimDeviceType.iPhone-11",
            "runtimeName" => "Latest from Selected Xcode (iOS 16.1)",
            "runtimeIdentifier" => "default",
            "kind" => "SIMULATOR"
        }
    when 'tvos'
        name = 'Test - tvOS'
        platform = 'TVOS'
        test_destination = {
            "deviceTypeName" : "Recommended Apple TVs",
            "deviceTypeIdentifier" : "recommended_apple_tvs",
            "runtimeName" : "Latest from Selected Xcode (tvOS 16.4)",
            "runtimeIdentifier" : "default",
            "kind" : "SIMULATOR"
        }
    when 'watchos'
        name = 'Test - watchOS'
        platform = 'WATCHOS'
        test_destination =  {
            "deviceTypeName" => "Recommended Apple Watches",
            "deviceTypeIdentifier" => "recommended_apple_watches",
            "runtimeName" => "Latest from Selected Xcode (watchOS 9.4)",
            "runtimeIdentifier" => "default",
            "kind" => "SIMULATOR"
        }
    else #docs, swiftlint, cocoapods, swiftpm
        return {
            "name" : "Build - macOS",
            "actionType" : "BUILD",
            "destination" : "ANY_MAC",
            "buildDistributionAudience" : null,
            "testConfiguration" : null,
            "scheme" : "CI",
            "platform" : "MACOS",
            "isRequiredToPass" : true
        }
    end

    build_action = {
        "name" => name,
        "actionType" => "TEST",
        "destination" => null,
        "buildDistributionAudience" => null,
        "testConfiguration" => {
            "kind" => "USE_SCHEME_SETTINGS",
            "testPlanName" => "",
            "testDestinations" => test_destination
        },
        "scheme" => scheme == "swift" ? "RealmSwift" : "Realm",
        "platform" => platform,
        "isRequiredToPass" => true
    }
end 

def get_xcode_id(version)
    list_xcodeversion = ''
    if $xcode_list != ''
        list_xcodeversion = $xcode_list
    else 
        list_xcodeversion = get_xcode_versions
        $xcode_list = list_xcodeversion
    end
    list_xcodeversion.each do |xcode|
        if xcode["name"] == "Xcode #{version}"
            return xcode["id"]
        end
    end
end

def get_macos_latest_release(xcodeVersionId)
    list_macosversion = ''
    if $mac_dict[xcodeVersionId] == ''
        list_macosversion = $mac_dict[xcodeVersionId]
    else 
        list_macosversion = get_macos_versions_for_xcode_version(xcodeVersionId)
        $mac_dict[xcodeVersionId] = list_macosversion
    end
    list_macosversion.each do |mac_os, id|
        if mac_os.include? "Latest Release"
            return id
        end
    end
end


def get_realm_product_id
    if $product_id != ''
        return $product_id
    end
    product = get_products
    product.each do |product|
        if product["product"] == "RealmSwift"
            $product_id = product["id"]
            return product["id"]
        end
    end
end

def get_realm_repository_id
    if $repository_id != ''
        return $repository_id
    end
    repositories = get_repositories
    repositories.each do |repo|
        if repo["name"] == "realm-swift"
            $repository_id = repo["id"]
            return repo["id"]
        end
    end
end

def get_workflow_id_for_name(name)
    workflows = ''
    if $workflows_list != ''
        workflows = $workflows_list
    else 
        workflows = get_workflows
        $workflows_list = workflows
    end
    workflows.each do |workflow|
        if workflow["attributes"]["name"].split('_')[0] == name
            return workflow["id"]
        end
    end
end

opts = GetoptLong.new(
    [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
    [ '--token', '-t', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--team-id', GetoptLong::OPTIONAL_ARGUMENT ],
    [ '--xcode-version', '-x', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--issuer-id', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--key-id', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--pk-path', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--list-workflows', GetoptLong::NO_ARGUMENT ],
    [ '--list-products', GetoptLong::NO_ARGUMENT ],
    [ '--list-repositories', GetoptLong::NO_ARGUMENT ],
    [ '--list-mac-versions', GetoptLong::NO_ARGUMENT ],
    [ '--list-xcode-versions', GetoptLong::NO_ARGUMENT ],
    [ '--info-workflow', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--create-workflow', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--update-workflow', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--delete-workflow', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--build-workflow', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--new-workflows', GetoptLong::NO_ARGUMENT ],
    [ '--clear-unused-workflows', GetoptLong::NO_ARGUMENT ],
    [ '--get-token', GetoptLong::NO_ARGUMENT ]
)

option = ''
name = ''
workflow_id = ''
xcode_version = ''
issuer_id = ''
key_id = ''
pk_path = ''

opts.each do |opt, arg|
    if opt != '--token' && opt != '--xcode-version' && opt != '--issuer-id' && opt != '--key-id' && opt != '--pk-path' && opt != '--team-id'
        option = opt
    end
    case opt
        when '--help'
            puts <<-EOF
hello [OPTION] ...

-h, --help:
    show help

--token [token], -t [token]:
    Apple connect API token 

--team-id [team_id]:
    Apple connect Tealm ID, to be used to return the url to the created workflow

--xcode-version [xcode_version]:
    XCode version used to create a new workflow

--issuer-id [issuer_id]:
    Apple Connect API Issuer ID.

--key-id [key_id]:
    Apple Connect API Key ID.

--pk-path [pk_path]:
    Apple Connect API path to private key file.

--list-workflows:
    Returns a list of current workflows for the RealmSwift product.

--list-products:
    Returns a list of products associated to the Apple Connect Store account.

--list-repositories:
    Returns a list of repositories integrated with XCode Cloud.

--list-mac-versions:
    Returns a list of available mac versions.

--list-xcode-versions:
    Returns a list of available xcode version.

--info-workflow [workflow_id]:
    Returns the infor the corresponding workflow.

--create-workflow [name]:
    Use with --xcode-version
    Create a new workflow with the corresponding name.

--update-workflow [workflow_id]:
    Updates workflow with the corresponding id.

--delete-workflow [workflow_id]:
    Delete the workflow with the corrresponding id.

--build-workflow [workflow_id]:
    Run a build for the corresponding workflow.

--new-workflows:
    Adds the missing workflows corresponding to the list of targets and xcode versions in `pr-ci-matrix.rb`.

--clear-unused-workflows:
    Clear all unused workflows which are not in the list of targets and xcode versions in `pr-ci-matrix.rb`.

--get-token:
    Get Apple Connect Store API Token for local use.

            EOF
            exit
        when '--token'
            if arg == ''
                raise "Token is required to execute this"
            else
                JWT_BEARER = arg
            end
        when '--team-id'
            if arg != ''
                TEAM_ID = arg
            end
        when '--issuer-id'
            if arg != ''
                issuer_id = arg
            end
        when '--key-id'
            if arg != ''
                key_id = arg
            end
        when '--pk-path'
            if arg != ''
                pk_path = arg
            end
        when '--info-workflow'
            if arg != ''
                workflow_id = arg
            end
        when '--create-workflow'
            if arg != ''
                name = arg
            end
        when '--delete-workflow', '--info-workflow', '--build-workflow', '--update-workflow'
            if arg != ''
                workflow_id = arg
            end
        when '--xcode-version'
            if arg != ''
                xcode_version = arg
            end
    end
end

if JWT_BEARER == '' && option != '--get-token'
    raise 'Token is needed to run this.'
end

if option == '--list-workflows'
    puts get_workflows
elsif option == '--list-products'
    puts get_products
elsif option == '--list-repositories'
    puts get_repositories
elsif option == '--list-mac-versions'
    puts get_macos_versions
elsif option == '--list-xcode-versions'
    puts get_xcode_versions
elsif option == '--info-workflow'
    if workflow_id == ''
        raise 'Needs workflow id'
    else
        print_workflow_info(workflow_id)
    end
elsif option == '--create-workflow'
    if name == '' || xcode_version == ''
        raise 'Needs name and xcode version'
    else
        create_workflow(name, xcode_version)
    end
elsif option == '--update-workflow'
    if workflow_id == ''
        raise 'Needs workflow id'
    else
        update_workflow(workflow_id)
    end
elsif option == '--delete-workflow'
    if workflow_id == ''
        raise 'Needs workflow id'
    else
        delete_workflow(workflow_id)
    end
elsif option == '--build-workflow'
    if workflow_id == ''
        raise 'Needs workflow id'
    else
        start_build(workflow_id)
    end
elsif option == '--new-workflows'
    if TEAM_ID == ''
        raise 'Needs workflow id'
    else
        create_new_workflows
    end
elsif option == '--clear-unused-workflows'
    delete_unused_workflows
elsif option == '--get-token'
    if issuer_id == '' || key_id == '' || pk_path == ''
        raise 'Needs issuer id, key id or pk id.'
    else
        get_jwt_bearer(issuer_id, key_id, pk_path)
    end
end

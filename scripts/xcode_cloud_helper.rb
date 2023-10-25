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

def usage()
    puts <<~END
    Usage: ruby #{__FILE__} --list-workflows
    Usage: ruby #{__FILE__} --list-products
    Usage: ruby #{__FILE__} --list-repositories
    Usage: ruby #{__FILE__} --list-mac-versions
    Usage: ruby #{__FILE__} --list-xcode-versions
    Usage: ruby #{__FILE__} --info-workflow [workflow_id]
    Usage: ruby #{__FILE__} --create-workflow [name] [xcode_version]
    Usage: ruby #{__FILE__} --delete-workflow [workflow_id]
    Usage: ruby #{__FILE__} --build-workflow [workflow_id]
    Usage: ruby #{__FILE__} --update-workflows
    Usage: ruby #{__FILE__} --clear-unused-workflows

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

def get_realm_product_id
    product = get_products
    product.each do |product|
        if product["product"] == "RealmSwift"
            return product["id"]
        end
    end
    return product
end

def get_realm_repository_id
    repositories = get_repositories
    repositories.each do |repo|
        if repo["name"] == "realm-swift"
            return repo["id"]
        end
    end
    return product
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
    [ '--delete-workflow', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--build-workflow', GetoptLong::REQUIRED_ARGUMENT ],
    [ '--update-workflows', GetoptLong::NO_ARGUMENT ],
    [ '--clear_unused', GetoptLong::NO_ARGUMENT ],
    [ '--get-token', GetoptLong::NO_ARGUMENT ]
)

JWT_BEARER = ''
TEAM_ID = ''

option = ''
name = ''
workflow_id = ''
xcode_version = ''
issuer_id = ''
key_id = ''
pk_path = ''

opts.each do |opt, arg|
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

--delete-workflow [workflow_id]:
    Delete the workflow with the corrresponding id.

--build-workflow [workflow_id]:
    Run a build for the corresponding workflow.

--update-workflows:
    Adds the missing workflows corresponding to the list of targets and xcode versions in `pr-ci-matrix.rb`.

--clear_unused:
    Clear all unused workflows which are not in the list of targets and xcode versions in `pr-ci-matrix.rb`.

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
                name = arg
            end
        when '--create-workflow'
            if arg != ''
                name = arg
            end
        when '--delete-workflow', '--info-workflow', '--build-workflow'
            if arg != ''
                workflow_id = arg
            end
            option = arg
        when '--xcode_version'
            if arg != ''
                workflow_id = arg
            end
            option = opt
        else
            option = opt
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
        get_workflow_info(workflow)
    end
elsif option == '--create-workflow'
    if name == '' || xcode_version == ''
        raise 'Needs name and xcode version'
    else
        create_workflow(name, xcode_version)
    end
elsif option == '--delete-workflow'
    if workflow_id == ''
        raise 'Needs workflow id'
    else
        deleteWorkflow(workflow)
    end
elsif option == '--build'
    if workflow_id == ''
        raise 'Needs workflow id'
    else
        start_build(workflow)
    end
elsif option == '--update-workflows'
    create_new_workflows
elsif option == '--clear-unused-workflows'
    delete_unused_workflows
elsif option == '--get-token'
    if issuer_id == '' || key_id == '' || pk_path == ''
        raise 'Needs issuer id, key id or pk id.'
    else
        get_jwt_bearer(issuer_id, key_id, pk_path)
    end
else
    raise 'Option not available'
end

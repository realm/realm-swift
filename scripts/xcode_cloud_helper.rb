#!/usr/bin/env ruby
require 'base64'
require 'json'
require 'jwt'
require 'net/http'
require 'net/https'
require 'optparse'
require 'pp'
require 'uri'
require_relative "pr-ci-matrix"

include Workflows

APP_STORE_URL = 'https://api.appstoreconnect.apple.com/v1'
HTTP = Net::HTTP.new('api.appstoreconnect.apple.com', 443)
HTTP.use_ssl = true

def request(req)
    req['Authorization'] = "Bearer #{JWT_TOKEN}"
    # puts req.path
    response = HTTP.request(req)
    raise "Error: #{response.code} #{response.body}" unless response.code =~ /20./
    response
end

def get(path)
    req = Net::HTTP::Get.new("/v1/#{path}")
    req['Accept'] = 'application/json'
    response = request req
    # puts response.body
    JSON.parse(response.body)
end

def post(path, body)
    req = Net::HTTP::Post.new("/v1/#{path}")
    req['Content-Type'] = 'application/json'
    req.body = body.to_json
    response = request req
    JSON.parse(response.body)
end

def get_jwt_bearer(issuer_id, key_id, pk_path)
    private_key = OpenSSL::PKey.read(File.read(pk_path))
    info = {
        iss: issuer_id,
        exp: Time.now.to_i + 10 * 60,
        aud: 'appstoreconnect-v1'
    }
    header_fields = { kid: key_id }
    JWT.encode(info, private_key, 'ES256', header_fields)
end

def get_workflows
    product_id = get_realm_product_id
    get("/ciProducts/#{product_id}/workflows?limit=200")['data']
end

def get_products
    get('ciProducts')['data'].map do |product|
        {
            id: product['id'],
            product: product['attributes']['name'],
            type: product['attributes']['productType']
        }
    end
end

def get_repositories
    response = get('scmRepositories')['data'].map do |repo|
        {
            id: repo['id'],
            name: repo['attributes']['repositoryName'],
            url: repo['attributes']['httpCloneUrl']
        }
    end
end

def get_macos_versions
    get('ciMacOsVersions')['data'].map do |macos|
        {
            id: macos['id'],
            name: macos['attributes']['name'],
            version: macos['attributes']['version']
        }
    end
end

def get_xcode_versions
    data = get('ciXcodeVersions')['data']
    Hash[data.collect { |xcode|
        [xcode['attributes']['name'], xcode['id']]
    }]
end

def get_workflow_info(id)
    get("ciWorkflows/#{id}")
end

def create_workflow(target, xcode_version)
    result = post('ciWorkflows', create_workflow_request(target, xcode_version))
    id = result["data"]["id"]
    puts "#{result['data']['attributes']['name']}: https://appstoreconnect.apple.com/teams/69a6de86-7f37-47e3-e053-5b8c7c11a4d1/frameworks/#{get_realm_product_id}/workflows/#{id}"
    return id
end

def create_workflow_request(target, xcode_version)
    xcode_version_id = get_xcode_id(xcode_version)
    return {
        data: {
            type: 'ciWorkflows',
            attributes: {
                name: "#{target.name}_#{xcode_version}",
                description: 'Create by Github Action Update XCode Cloud Workflows',
                isLockedForEditing: false,
                containerFilePath: 'Realm.xcodeproj',
                isEnabled: false,
                clean: false,
                pullRequestStartCondition: {
                    source: {
                        isAllMatch: true,
                        patterns: []
                    },
                    destination: {
                        isAllMatch: true,
                        patterns: []
                    },
                    autoCancel: true
                },
                actions: [target.action]
            },
            relationships: {
                xcodeVersion: {
                    data: {
                        type: 'ciXcodeVersions',
                        id: xcode_version_id
                    }
                },
                macOsVersion: {
                    data: {
                        type: 'ciMacOsVersions',
                        id: get_macos_latest_release(xcode_version_id)
                    }
                },
                product: {
                    data: {
                        type: 'ciProducts',
                        id: get_realm_product_id
                    }
                },
                repository: {
                    data: {
                        type: 'scmRepositories',
                        id: get_realm_repository_id
                    }
                }
            }
        }
    }
end

def enable_workflow(id)
    req = Net::HTTP::Patch.new("/v1/ciWorkflows/#{id}")
    req['Content-type'] = 'application/json'
    req.body = {
        data: {
            type: 'ciWorkflows',
            attributes: {
                isEnabled: true
            },
            id: id
        }
    }.to_json
    response = request req
    puts response.body
    result = JSON.parse(response.body)
    id = result['data']['id']
    puts "Workflow updated #{id}"
    return id
end

def delete_workflow(id)
    req = Net::HTTP::Delete.new("/v1/ciWorkflows/#{id}")
    req['Content-type'] = 'application/json'
    response = request req
    puts "Workflow deleted #{id}"
end

def start_build(id)
    result = post('ciBuildRuns', {
        data: {
            type: 'ciBuildRuns',
            attributes: {},
            relationships: {
                workflow: {
                    data: {
                        type: 'ciWorkflows',
                        id: id
                    }
                }
            }
        }
    })
    id = result['data']['id']
    puts "Workflow build started with id: #{id}:"
    puts result
    return id
end

def get_macos_version_for_xcode_version(version)
    result = get("ciXcodeVersions/#{version}/macOsVersions")
    latest = result['data'].find { |version| version['attributes']['name'] == 'Latest Release' }
    latest['id']
end

def synchronize_workflows()
    desired_workflows = Workflows::TARGETS.flat_map { |target|
        Workflows::XCODE_VERSIONS.filter_map { |version|
            if target.filter.call(version)
                {target: target, version: version}
            end
        }
    }
    current_workflows = get_workflows.filter_map { |workflow|
        name = workflow['attributes']['name']
        # don't touch release pipeline jobs
        next if name.include? 'release_'
        pieces = name.partition('_')
        {name: pieces.first, version: pieces.last, id: workflow['id']}
    }

    workflows_to_remove = current_workflows.reject { |current|
        desired_workflows.find { |desired|
            desired[:target].name == current[:name] && desired[:version] == current[:version]
        }
    }
    workflows_to_create = desired_workflows.reject { |desired|
        current_workflows.find { |current|
            desired[:target].name == current[:name] && desired[:version] == current[:version]
        }
    }

    puts 'Workflows to remove:'
    workflows_to_remove.each { |w|
        puts "- #{w[:name]}: #{w[:version]}"
    }
    puts ''
    puts 'Workflows to create:'
    workflows_to_create.each { |w|
        puts "- #{w[:target].name}: #{w[:version]}"
    }
    puts ''
    print 'Do you wish to continue [create/delete/both/quit]? '

    case STDIN.gets.chomp.downcase
    when 'create'
        workflows_to_remove = []
    when 'delete'
        workflows_to_create = []
    when 'both'
    when 'quit'
        puts 'Exiting without making any changes'
        exit 0
    else
        puts 'Unrecoginized command'
        exit 1
    end

    workflows_to_create.each { |w|
        create_workflow(w[:target], w[:version])
    }
    workflows_to_remove.each { |w|
        delete_workflow(w[:id])
    }
end

$xcode_ids = nil
def get_xcode_id(version)
    $xcode_ids ||= get_xcode_versions
    id = $xcode_ids["Xcode #{version}"]
    if not id
        puts "Nonexistent Xcode version #{version}"
        puts "Valid versions are:"
        $xcode_ids.keys.each { |v| puts "- #{v}"}
        exit 1
    end
    id
end

$mac_dict = Hash.new { |h, k| h[k] = get_macos_version_for_xcode_version(k) }
def get_macos_latest_release(xcodeVersionId)
    return $mac_dict[xcodeVersionId]
end

$product_id = nil
def get_realm_product_id
    $product_id ||= get_products.find { |p| p[:product] == 'RealmSwift' }[:id]
end

$repository_id = nil
def get_realm_repository_id
    $repository_id ||= get_repositories.find { |repo| repo[:name] == 'realm-swift' }[:id]
end

$workflows_list = nil
def get_workflow_id_for_name(name)
    $workflows_list ||= get_workflows
    $workflows_list.find { |w| w['attributes']['name'].split('_')[0] == name }['id']
end

Options = Struct.new(:token, :team_id, :issuer_id, :key_id, :pk_path)
options = Options.new()
$parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby #{__FILE__} [options] command"
    opts.separator <<~END

    All commands require either --token or all three of --issuer-id, --key-id,
    and --pk-path to automatically create a token.

    Commands:
      list-workflows
        Returns a list of current workflows for the RealmSwift product.
      list-products
        Returns a list of products associated to the Apple Connect Store account.
      list-repositories
        Returns a list of repositories integrated with XCode Cloud.
      list-mac-versions
        Returns a list of available mac versions.
      list-xcode-versions
        Returns a list of available xcode version.
      info-workflow workflow_id
        Returns the info for the corresponding workflow.
      synchronize-workflows
        Delete old workflows and/or create new ones.
      build-workflow workflow-id
        Run a build for the corresponding workflow.
      get-token
        Get Apple Connect Store API Token for local use.

    Options:
    END

    opts.on("-h", "--help", "Display this help") do
        puts opts
        exit 0
    end
    opts.on('-t TOKEN', '--token TOKEN', 'Apple Connect API token') do |token|
        options[:token] = token
    end
    opts.on('--issuer-id ID', 'Apple Connect API Issuer ID.') do |id|
        options[:issuer_id] = id
    end
    opts.on('--key-id ID', 'Apple Connect API Key ID.') do |id|
        options[:key_id] = id
    end
    opts.on('--pk-path PATH', 'Apple Connect API path to private key file.') do |path|
        options[:pk_path] = path
    end
end
$parser.parse!

def usage()
    puts $parser
    exit 1
end

JWT_TOKEN = options[:token] || begin
    usage if not options[:issuer_id] or not options[:key_id] or not options[:pk_path]
    get_jwt_bearer(options[:issuer_id], options[:key_id], options[:pk_path])
end

COMMAND = ARGV.shift
usage unless COMMAND

case COMMAND
when 'list-workflows'
    pp get_workflows
when 'list-products'
    pp get_products
when 'list-repositories'
    pp get_repositories
when 'list-mac-versions'
    pp get_macos_versions
when 'list-xcode-versions'
    pp get_xcode_versions
when 'info-workflow'
    workflow_id = ARGV.shift
    usage unless workflow_id
    pp get_workflow_info(workflow_id)
when 'enable-workflow'
    workflow_id = ARGV.shift
    usage unless workflow_id
    enable_workflow(workflow_id)
when 'synchronize-workflows'
    synchronize_workflows()
when 'build-workflow'
    workflow_id = ARGV.shift
    usage unless workflow_id
    start_build(workflow_id)
when 'get-token'
    pp JWT_TOKEN
end

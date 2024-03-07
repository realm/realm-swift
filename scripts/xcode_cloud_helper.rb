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
require_relative "release-matrix"

include Workflows

APP_STORE_URL = 'https://api.appstoreconnect.apple.com/v1'
HTTP = Net::HTTP.new('api.appstoreconnect.apple.com', 443)
HTTP.use_ssl = true
HTTP.max_retries = 2

def sh(*args)
    puts "executing: #{args.join(' ')}" if false
    system(*args, false ? {} : {:out => '/dev/null'}) || exit(1)
end

def request(req)
    req['Authorization'] = "Bearer #{JWT_TOKEN}"
    # puts req.path
    counter = 0
    while true do
        sleep 5
        counter +=1
        response = HTTP.request(req)
    break if (response.code =~ /20./ ) == 0
    break if counter == 2
    end

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

def get_jwt_bearer_from_file(issuer_id, key_id, pk_path)
    private_key = File.read(pk_path)
    get_jwt_bearer(issuer_id, key_id, private_key)
end

def get_jwt_bearer(issuer_id, key_id, pk)
    private_key = OpenSSL::PKey.read(pk)
    info = {
        iss: issuer_id,
        exp: Time.now.to_i + 20 * 60,
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

def get_build_actions(build_run)
    get("/ciBuildRuns/#{build_run}/actions")['data'].map do |build_run|
        {
            id: build_run['id'],
        }
    end
end

def get_artifacts(build_action)
    get("/ciBuildActions/#{build_action}/artifacts")['data'].map do |artifact|
        {
            id: artifact['id'],
        }
    end
end

def get_git_references
    repository_id = get_realm_repository_id
    get("/scmRepositories/#{repository_id}/gitReferences?limit=200")
end

def get_workflow_info(id)
    get("ciWorkflows/#{id}")
end

def get_build_info(id)
    get("/ciBuildRuns/#{id}")
end

def get_artifact_info(id)
    get("/ciArtifacts/#{id}")
end

def create_workflow(target, xcode_version, pull_request)
    result = post('ciWorkflows', create_workflow_request(target, xcode_version, pull_request))
    id = result["data"]["id"]
    return id
end

def create_workflow_request(target, xcode_version, pull_request)
    xcode_version_id = get_xcode_id(xcode_version)
    data = {
        data: {
            type: 'ciWorkflows',
            attributes: {
                name: "#{target.name}_#{xcode_version}",
                description: 'Create by Github Action Update XCode Cloud Workflows',
                isLockedForEditing: false,
                containerFilePath: 'Realm.xcodeproj',
                isEnabled: true,
                clean: false,
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

    if pull_request
        data[:data][:attributes][:pullRequestStartCondition] = {
            source: {
                isAllMatch: true,
            },
            destination: {
                isAllMatch: true,
            },
            autoCancel: true
        }
    else
        data[:data][:attributes][:manualBranchStartCondition] = {
            source: {
                isAllMatch: true,
            },
            destination: {
                isAllMatch: true,
            },
            autoCancel: true
        }
    end

    data
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
end

def start_build(id, branch)
    branch_id = find_git_reference_for_branch(branch)
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
                },
                sourceBranchOrTag: {
                    data: {
                        type: 'scmGitReferences',
                        id: branch_id
                    }
                }
            }
        }
    })
    id = result['data']['id']
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
        next if name.start_with? 'release-'
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
        id = create_workflow(w[:target], w[:version], true)
        puts "#{w[:target]}: https://appstoreconnect.apple.com/teams/69a6de86-7f37-47e3-e053-5b8c7c11a4d1/frameworks/#{get_realm_product_id}/workflows/#{id}"
    }
    workflows_to_remove.each { |w|
        delete_workflow(w[:id])
        puts "Workflow deleted #{w[:name]}"
    }
end

def get_build_status(build_run)
    build_state = get_build_info(build_run)
    status = build_state["data"]["attributes"]["executionProgress"]
    return status
end

def get_build_result(build_run)
    build_state = get_build_info(build_run)
    completion_status = build_state["data"]["attributes"]["completionStatus"]
    return completion_status
end

def get_logs_for_build(build_run)
    actions = get_build_actions(build_run)
    artifacts = get_artifacts(actions[0][:id]) # we are only running one action, so we use the first one in the list
    artifact_url = ''
    artifacts.each { |artifact|
        artifact_info = get_artifact_info(artifact[:id])
        if artifact_info["data"]["attributes"]["fileName"].include? 'Logs'
            artifact_url = artifact_info["data"]["attributes"]["downloadUrl"]
        end
    }
    print_logs(artifact_url)
end

def print_logs(url)
    sh 'curl', '--output', 'logs.zip', "#{url}"
    sh 'unzip', '-o', 'logs.zip'
    log_files = Dir["RealmSwift*/*.log"]
    log_files.each { |log_file|
        text = File.readlines("#{log_file}").map do |line|
            puts line
        end
    }
end

def find_git_reference_for_branch(branch)
    next_page = ''
    references = get_git_references
    branch_reference = references["data"].find { |reference|
        reference["attributes"]["kind"] == "BRANCH" && reference["attributes"]["name"] == branch
    }
    while branch_reference == nil || next_page == nil
        next_page = references["links"]["next"]
        next_page.slice!(APP_STORE_URL)
        references = get(next_page)
        branch_reference = references["data"].find { |reference| reference["attributes"]["kind"] == "BRANCH" && reference["attributes"]["name"] == branch }
    end
    return branch_reference["id"]
end

def download_artifact_for_build(build_id_run)
    actions = get_build_actions(build_id_run)
    artifacts = get_artifacts(actions[0][:id]) # One actions per workflow
    artifact_url = ''
    artifacts.each { |artifact|
        artifact_info = get_artifact_info(artifact[:id])
        if artifact_info["data"]["attributes"]["fileName"].include? 'Products'
            artifact_url = artifact_info["data"]["attributes"]["downloadUrl"]
        end
    }

    sh 'curl', '--output', "xcode-cloud-build-#{build_id_run}.zip", "#{artifact_url}"
end

def clean_up_release_workflows()
    workflows_to_remove = get_workflows.filter_map { |workflow|
        if workflow['attributes']['name'].start_with?('release-package-build')
            {name: workflow['attributes']['name'], id: workflow['id']}
        end
    }
    workflows_to_remove.each { |w|
        delete_workflow(w[:id])
        puts "Workflow deleted #{w[:name]}"
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

Options = Struct.new(:token, :team_id, :issuer_id, :key_id, :pk_path, :pk)
options = Options.new()
$parser = OptionParser.new do |opts|
    opts.banner = "Usage: ruby #{__FILE__} [options] command"
    opts.separator <<~END

    All commands require either --token or all three of --issuer-id, --key-id,
    and --pk-path or --pk to automatically create a token.

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
      create-workflow platform xcode_version target configuration
        Creates a workflow to create platform framework for an specific configuration, target and xcode version.
      delete-workflow workflow-id
        Deletes the workflow.
      wait-build build_id
        Check status of a current build and waits, returns when completed or fails.
      download-artifact build_id
        Download a build artifact for any given build run with a build action.
      clean-up-release-workflows
        Cleans all workflows created for a release (starts with release-package-build).
      get-build-status
        Get build current status.
      get-build-result
        Get build run completion status (Complete, Error).
      print-build-logs
        Print build logs.
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
    opts.on('--pk PK', 'Apple Connect API private key.') do |pk|
        options[:pk] = pk
    end
end
$parser.parse!

def usage()
    puts $parser
    exit 1
end

if options[:issuer_id] and options[:key_id] and options[:pk_path]
    JWT_TOKEN = get_jwt_bearer_from_file(options[:issuer_id], options[:key_id], options[:pk_path])
elsif options[:issuer_id] and options[:key_id] and options[:pk]
    JWT_TOKEN = get_jwt_bearer(options[:issuer_id], options[:key_id], options[:pk])
elsif options[:token]
    JWT_TOKEN = options[:token]
else
    usage
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
    branch = ARGV.shift
    usage unless workflow_id
    id = start_build(workflow_id, branch)
    puts id
when 'create-workflow'
    prefix = ARGV.shift
    platform = ARGV.shift
    xcode_version = ARGV.shift
    target = ARGV.shift
    configuration = ARGV.shift
    usage unless platform and xcode_version and target and configuration
    release_target = ReleaseTarget.new("#{prefix}-#{platform}-#{target}-#{configuration}", target, platform)
    id = create_workflow(release_target, xcode_version, false)
    puts id
when 'delete-workflow'
    workflow_id = ARGV.shift
    delete_workflow(workflow_id)
when 'download-artifact'
    build_id = ARGV.shift
    usage unless build_id
    download_artifact_for_build(build_id)
when 'clean-up-release-workflows'
    clean_up_release_workflows()
when 'get-build-status'
    build_id = ARGV.shift
    status = get_build_status(build_id)
    puts status
when 'get-build-result'
    build_id = ARGV.shift
    usage unless build_id
    completion_status = get_build_result(build_id)
    puts completion_status
when 'print-build-logs'
    build_id = ARGV.shift
    usage unless build_id
    get_logs_for_build(build_id)
when 'get-token'
    puts JWT_TOKEN
end

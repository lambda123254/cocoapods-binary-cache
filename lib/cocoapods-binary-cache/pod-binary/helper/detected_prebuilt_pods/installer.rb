# MODIFIED
module Pod
  class Installer
    # Returns the names of pod targets detected as prebuilt, including
    # those declared in Podfile and their dependencies
    def prebuilt_pod_names
      prebuilt_pod_targets.map(&:name).to_set
    end

    # Returns the pod targets detected as prebuilt, including
    # those declared in Podfile and their dependencies

    # Pods dependencies which is not :binary => false, will act still as a binary
    def prebuilt_pod_targets
      @prebuilt_pod_targets ||= begin
        explicit_prebuilt_pod_names = aggregate_targets
        .flat_map { |target| target.target_definition.explicit_prebuilt_pod_names }
        .select { |pod| pod[:binary] == true }
        .map { |pod| pod[:name] }
        .uniq

       
        targets = pod_targets.select { |target| explicit_prebuilt_pod_names.include?(target.pod_name) }
        dependencies = targets.flat_map(&:recursive_dependent_targets)
        all = (targets + dependencies).uniq

        all = all.select do |target|
          binary_value = find_binary_status_for_pod(target.pod_name)
          binary_value.nil? || binary_value == true  # Only include :binary => true or nil
        end
        
        all = all.reject { |target| sandbox.local?(target.pod_name) } unless PodPrebuild.config.dev_pods_enabled?
        all
      end

    end

    def find_binary_status_for_pod(pod_name)
      explicit_prebuilt_pod = aggregate_targets
        .flat_map { |target| target.target_definition.explicit_prebuilt_pod_names }
        .find { |pod| pod[:name] == pod_name }

      explicit_prebuilt_pod.nil? ? nil : explicit_prebuilt_pod[:binary]
    end
  end
end

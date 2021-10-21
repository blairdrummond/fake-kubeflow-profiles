// Defines a function that creates the profile as well as a
// RoleBinding and a ServiceRoleBinding for every owner of
// the namespace being created.

local rolebinding = function (name, owner)
{
  "apiVersion": "rbac.authorization.k8s.io/v1",
  "kind": "RoleBinding",
  "metadata": {
    "annotations": {
      "role": "admin",
      "user": owner
    },
    "name": "namespaceAdmin-" + std.strReplace(std.strReplace(owner, ".", "-"), "@", "-"),
    "namespace": name
  },
  "roleRef": {
    "apiGroup": "rbac.authorization.k8s.io",
    "kind": "ClusterRole",
    "name": "kubeflow-admin"
  },
  "subjects": [
    {
      "apiGroup": "rbac.authorization.k8s.io",
      "kind": "User",
      "name": owner
    }
  ]
};

local serviceRoleBinding = function (name, owner)
{
  "apiVersion": "rbac.istio.io/v1alpha1",
  "kind": "ServiceRoleBinding",
  "metadata": {
    "annotations": {
      "role": "edit",
      "user": owner
    },
    "generation": 1,
    "name": "user-" + std.strReplace(std.strReplace(owner, ".", "-"), "@", "-") + "-clusterrole-edit",
    "namespace": name
  },
  "spec": {
    "roleRef": {
      "kind": "ServiceRole",
      "name": "ns-access-istio"
    },
    "subjects": [
      {
        "properties": {
          "request.headers[kubeflow-userid]": owner
        }
      }
    ]
  }
};

// Creates the profile CR and calls the functions to create the
// RoleBinding and ServiceRoleBinding resources for each owner.
// Returned as an array of k8s manifests.
//  
// @param name The name of the profile/namespace to create
// @param owners The array of owners on this namespace
// @param root_owner The inital owner used to bootstrap the namespace
// 
// Note: root_owner is intentionally defaulted to a person who does
// not exist, because atm kubeflow doesn't offer a way to uncreate
// the rolebinding, and we want to allow multiple owners.
function (name, owners, root_owner="nobody@statcan.gc.ca")
[
  {
    "apiVersion": "kubeflow.org/v1",
    "kind": "Profile",
    "metadata": {
      "name": name
    },
    "spec": {
      "owner": {
        "kind": "User",
        "name": root_owner
      }
    }
  }
] + [ rolebinding(name, owner) for owner in owners ] + 
[ serviceRoleBinding(name, owner) for owner in owners ]

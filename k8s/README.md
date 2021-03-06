# k8s
This has been tested against Kubernetes v1.23.6 with Metallb v0.12.1 and nfs-subdir-external-provisioner v4.0.13.

### configmap.yaml
Contains the serverDZ.cfg and BEServer_x64.cfg files.  You'll want to add your own configuration here.

### deployment.yaml
The deployment will create a pod with 2 containers.  One being the container that dayz run's in and the a second container that run's sshd.  The second container can be used to transfer mod's or copy custom configuration files, ie types.xml.

For more options regarding the openssh server container see, https://hub.docker.com/r/linuxserver/openssh-server.

### namespace.yaml
Creates the namespace.

*default: dayz*

### pvc.yaml
Creates the PVC's that the deployment uses.  Current PVC's:

*dayz-data-pvc: 100Gi* - Used for the server files.

*dayz-profile-pvc: 50Gi* - The DayZ dedicated server profile for the instance.

*ssh-config-pvc: 1Gi* - Used by the ssh container for things like logs and host ssh key.

### secrets.yaml
Creates the secret that contains the ssh username and password.  You have to base64 encode both values.

### svc.yaml
Creates the K8s service that you can use to connect to the pod.  Note that in my environment I'm using metallb in layer2 mode.  This is enough for my configuration but you may have different needs.  The svc.yaml file expects that you will specify the IP for the pod.  It creates two services, one for udp and the other for tcp ports.

### cronjob.yaml
Configures the cronjob that triggers a restart of the deployment every X hours.  By default it's set to 12 hours.

### rbac.yaml
Contains the Role and Rolebinding for the service account used by the cronjob.

### serviceaccount.yaml
Creates the service account used by the restart-dayz cronjob.

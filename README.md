# dayz-dedicated-server-k8s

Run a DayZ Dedicated Server on Kubernetes.

Will deploy a DayZ Dedicated Server on your K8s cluster.  It deploys the linux experimental server and you must use the experimental client to connect to your pod.  The server will not show up in the server browser so you'll need to connect to it directly.  Currently this is a vanilla deployment of the server.  Might include ways to load mods into this later.

Docker container based off the steamcmd container.  Read the k8s readme before using.

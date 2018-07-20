# Configuration file for jupyterhub.

import os
notebook_dir = os.environ.get('DOCKER_NOTEBOOK_DIR')
network_name='jupyterhub-network'

c.Spawner.debug = True
c.Spawner.environment = {'SPARKMAGIC_CONF_DIR':'/etc/jupyter/conf'}

c.JupyterHub.hub_ip = '0.0.0.0'
c.JupyterHub.admin_access = True
c.JupyterHub.ssl_key = '/etc/jupyter/conf/server.key'
c.JupyterHub.ssl_cert = '/etc/jupyter/conf/server.crt'
c.JupyterHub.port = 9443

c.Authenticator.admin_users = {'jovyan'}

# Configuration file for jupyter-notebook.


<% if @use_s3_persistence -%>
from s3contents import S3ContentsManager

config = get_config()

# Tell Jupyter to use S3ContentsManager for all storage.
config.NotebookApp.contents_manager_class = S3ContentsManager
config.S3ContentsManager.bucket = "<%= @s3_persistence_bucket %>"
import os
user = os.environ['JUPYTERHUB_USER']
config.S3ContentsManager.prefix = os.path.join("jupyter", user)
<% end -%>



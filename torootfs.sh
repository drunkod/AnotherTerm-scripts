#!/system/bin/sh

# This is a script that extracts the rootfs from a docker image and saves it as a tar file
# The script takes two arguments: the name of the docker image and the output file name
# The script assumes that docker is installed and running on the system

# Check if the arguments are valid
if [ $# -ne 2 ]; then
  echo "Usage: $0 image_name output_file"
  exit 1
fi

# Assign the arguments to variables
image_name=$1
output_file=$2

# Create a temporary container from the image
container_id=$(docker create $image_name)

# Export the container's filesystem to a tar file
docker export $container_id > $output_file

# Remove the temporary container
docker rm $container_id

# Print a success message
echo "The rootfs of $image_name has been extracted to $output_file"
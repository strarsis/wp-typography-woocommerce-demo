#!/usr/bin/env sh


# Host + Port parameters required for setting up the WordPress site
Host=${1?Host required}
Port=${2?Port required}


# Wait until WordPress container became ready
# See also https://github.com/wp-cli/wp-cli/issues/4106 .
until sleep 2s ; docker-compose exec wordpress \
  sudo -u www-data \
    wp db check > /dev/null
do
  echo "Waiting for WordPress container becoming ready..."
done
echo "WordPress container ready."

# Finish installation
docker-compose exec wordpress \
  wp core install \
    --allow-root \
    --skip-email \
    --path=/var/www/html \
    --url=$Host:$Port \
    --title="Example site" \
    --admin_user=admin \
    --admin_password="test" \
    --admin_email=info@example.com

# Install + activate plugins
docker-compose exec wordpress \
  wp plugin install \
      --allow-root \
      --path=/var/www/html \
      --activate \
      woocommerce wp-typography \

# Install + activate theme
docker-compose exec wordpress \
  wp theme install \
      --allow-root \
      --path=/var/www/html \
      --activate \
      storefront

# Create page for being the WooCoommerce Shop-Page
new_page_id=$( \
docker-compose exec wordpress \
  wp post create \
      /tmp/test/page.txt \
      --allow-root \
	  --porcelain \
      --path=/var/www/html \
      --post_type=page \
      --post_status=publish \
      --post_title="Shop-Page" \
)

# Assign the new page as WooCommerce Shop-Page
docker-compose exec wordpress \
  sudo -u www-data \
    wp option update \
      --path=/var/www/html \
        woocommerce_shop_page_id "$new_page_id" \

echo "Setup completed, you should now be able to visit the example site on  http://$Host:$Port".

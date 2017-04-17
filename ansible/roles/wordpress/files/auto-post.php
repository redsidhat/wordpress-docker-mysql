<?php
require ('wp-load.php');
$url = 'https://www.metaweather.com/api/location/2379574/';

$cURL = curl_init();

curl_setopt($cURL, CURLOPT_URL, $url);
curl_setopt($cURL, CURLOPT_HTTPGET, true);
curl_setopt($cURL, CURLOPT_RETURNTRANSFER, true);
curl_setopt($cURL, CURLOPT_HTTPHEADER, array(
    'Content-Type: application/json',
    'Accept: application/json'
));

$result = curl_exec($cURL);
curl_close($cURL);
$obj = json_decode($result, TRUE);

$wsn = $obj['consolidated_weather'][0]['weather_state_name'];
$wsa = $obj['consolidated_weather'][0]['weather_state_abbr'];
$temp = $obj['consolidated_weather'][0]['the_temp'];
$icon_url = "https://www.metaweather.com/static/img/weather/$wsa.svg";

$content = "Weather is $wsn. \n Temperature is $temp F. <img src=$icon_url\>";

$my_post = array(
  'post_title'    => 'Chicago Weather',
  'post_content'  => $content,
  'post_status'   => 'publish',
  'post_author'   => $user_ID,
);


wp_insert_post( $my_post, $wp_error );

?>
<%@taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@page contentType="text/html" pageEncoding="UTF-8" %>
<html>
	<head>
		<meta charset="utf-8" />
		<title>DemoFYS</title>

		<script src="https://maps.googleapis.com/maps/api/js?key=AIzaSyCx1XNc4JHeS-Vl7Gfyv5b1Et940jzToFE"></script>
		<script src="<c:url value="/assets/js/jquery-3.2.1.min.js" />"></script>
	</head>
	<body style="margin:0">
		<div id="googleMap" style="width:100%;height:100%;"></div>
		<div style="position:absolute; right:0; top:0; z-index:9999; margin-right:10px;">
			<h3 id="altitude" style="margin:0;"></h3>
			<h3 id="time" style="margin:0;"></h3>
		</div>
		<script>
			var TIME_BETWEEN_UPDATES = 1000;
			var TIME_OFFSET = 0;
			var TIMEZONE_REQUEST_INTERVAL = 20;
			var TIMEZONE_COUNTER = 0;
			var PLANE_SCALE = 0.075;

			var line = null;

			function initialize() {
				var mapProp = {
//					center: new google.maps.LatLng(51.508742, -0.120850),
					zoom: 5
				};
				var map = new google.maps.Map(document.getElementById("googleMap"), mapProp);

				var marker = new google.maps.Marker({
					icon: {
						path: 'M497.25,357v-51l-204-127.5V38.25C293.25,17.85,275.4,0,255,0c-20.4,0-38.25,17.85-38.25,38.25V178.5L12.75,306v51    l204-63.75V433.5l-51,38.25V510L255,484.5l89.25,25.5v-38.25l-51-38.25V293.25L497.25,357z'
					}
				});

				marker.setMap(map);

				line = renderLine(map);
				keepUpdatingMapIcons(map, marker);
			}

			function resetLine() {
				var lineCoords = line.getPaths();
				lineCoords = [];
				line.setPaths(lineCoords);
			}

			function keepUpdatingMapIcons(map, marker) {
				setTimeout(function () {
					var request = $.ajax({
						url: "/gps",
						method: "get",
						dataType: 'json'
					});

					request.done(function (msg) {
						moveMarker(map, marker, msg);
						line = refreshLine(line, msg.latitude, msg.longitude);
						keepUpdatingMapIcons(map, marker, line);

						if (TIMEZONE_COUNTER == 0) {
							getTimeZone(msg.latitude, msg.longitude);
							map.panTo(new google.maps.LatLng(msg.latitude, msg.longitude));
						} else if (TIMEZONE_COUNTER >= TIMEZONE_REQUEST_INTERVAL) {
							getTimeZone(msg.latitude, msg.longitude);
							TIMEZONE_COUNTER = 0;
						}
						TIMEZONE_COUNTER++;
					});

					request.fail(function () {
						alert("Map Refresh Failed. Reload the page to try again.");
					});
				}, TIME_BETWEEN_UPDATES);
			}

			function refreshLine(line, lat, lng) {
				var lineCoords = line.getPaths();
				lineCoords.push({lat: lat, lng: lng});
				line.setPaths(lineCoords);
				return line;
			}

			function renderLine(map) {
				var request = $.ajax({
					url: '/gpslist',
					method: 'get',
					dataType: 'json'
				});

				var lineCoords = request.done(function (msg) {
					var lineCoords = [];
					msg.forEach(function (location) {
						lineCoords.push({lat: location.latitude, lng: location.longitude});
					});
					var line = new google.maps.Polygon({
						paths: lineCoords,
						strokeColor: '#FF0000',
						strokeOpacity: 1,
						strokeWeight: 2
					});
					line.setMap(map);
				});
				return line;
			}

			function getTimeZone(x, y) {
				var request = $.ajax({
					url: "https://maps.googleapis.com/maps/api/timezone/json?location=" + x + "," + y + "&timestamp=1458000000&key= AIzaSyAgPe8wa5rvsBp1XoI_83O2DamD4ks8WBY",
					method: "get",
					dataType: 'json'
				});

				request.done(function (msg) {
					if (msg.rawOffset) {
						TIME_OFFSET = msg.rawOffset;
					}
				});
			}

			function moveMarker(map, marker, msg) {
				var newCoordinate = new google.maps.LatLng(msg.latitude, msg.longitude);
				marker.setPosition(newCoordinate);
				marker.icon.rotation = msg.course;

				marker.setIcon({
					rotation: msg.course,
					scale: PLANE_SCALE,
					fillColor: 'black',
					fillOpacity: 1,
					path: "M497.25,357v-51l-204-127.5V38.25C293.25,17.85,275.4,0,255,0c-20.4,0-38.25,17.85-38.25,38.25V178.5L12.75,306v51    l204-63.75V433.5l-51,38.25V510L255,484.5l89.25,25.5v-38.25l-51-38.25V293.25L497.25,357z",
					anchor: new google.maps.Point(250, 500)
				});

				var time = msg.timestamp + TIME_OFFSET;
				var hours = Math.floor(time / 3600);
				time = time - hours * 3600;
				var minutes = Math.floor(time / 60);

				$("#altitude").text(Math.round(msg.altitude) + " m");
				$("#time").text(str_pad_left(hours, '0', 2) + ':' + str_pad_left(minutes, '0', 2));
			}

			function str_pad_left(string, pad, length) {
				return (new Array(length + 1).join(pad) + string).slice(-length);
			}

			$(document).ready(function () {
				initialize();
			});
		</script>
	</body>
</html>

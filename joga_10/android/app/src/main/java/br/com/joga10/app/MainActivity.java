package br.com.joga10.app;

import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.net.Uri;

import androidx.annotation.NonNull;

import com.google.android.gms.maps.model.LatLng;
import com.google.android.libraries.places.api.Places;
import com.google.android.libraries.places.api.model.CircularBounds;
import com.google.android.libraries.places.api.model.OpeningHours;
import com.google.android.libraries.places.api.model.Place;
import com.google.android.libraries.places.api.net.FetchPlaceRequest;
import com.google.android.libraries.places.api.net.PlacesClient;
import com.google.android.libraries.places.api.net.SearchByTextRequest;
import com.google.android.libraries.places.api.net.SearchNearbyRequest;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "br.com.joga10.app/google_places";

    private static final List<String> SPORTS_TYPES = Arrays.asList(
            "arena",
            "athletic_field",
            "playground",
            "sports_activity_location",
            "sports_club",
            "sports_complex",
            "stadium",
            "swimming_pool",
            "tennis_court"
    );

    private static final List<Place.Field> SEARCH_FIELDS = Arrays.asList(
            Place.Field.ID,
            Place.Field.DISPLAY_NAME,
            Place.Field.FORMATTED_ADDRESS,
            Place.Field.LOCATION,
            Place.Field.PRIMARY_TYPE,
            Place.Field.PRIMARY_TYPE_DISPLAY_NAME,
            Place.Field.TYPES,
            Place.Field.BUSINESS_STATUS,
            Place.Field.RATING,
            Place.Field.USER_RATING_COUNT
    );

    private static final List<Place.Field> DETAIL_FIELDS = Arrays.asList(
            Place.Field.ID,
            Place.Field.DISPLAY_NAME,
            Place.Field.FORMATTED_ADDRESS,
            Place.Field.LOCATION,
            Place.Field.PRIMARY_TYPE,
            Place.Field.PRIMARY_TYPE_DISPLAY_NAME,
            Place.Field.TYPES,
            Place.Field.BUSINESS_STATUS,
            Place.Field.RATING,
            Place.Field.USER_RATING_COUNT,
            Place.Field.NATIONAL_PHONE_NUMBER,
            Place.Field.WEBSITE_URI,
            Place.Field.GOOGLE_MAPS_URI,
            Place.Field.OPENING_HOURS
    );

    private PlacesClient placesClient;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        initializePlaces();
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(this::handlePlacesCall);
    }

    private void initializePlaces() {
        try {
            ApplicationInfo info = getPackageManager().getApplicationInfo(
                    getPackageName(),
                    PackageManager.GET_META_DATA
            );
            String apiKey = info.metaData.getString("com.google.android.geo.API_KEY", "");
            if (!Places.isInitialized() && !apiKey.isEmpty()) {
                Places.initializeWithNewPlacesApiEnabled(getApplicationContext(), apiKey);
            }
            if (Places.isInitialized()) {
                placesClient = Places.createClient(this);
            }
        } catch (PackageManager.NameNotFoundException ignored) {
            placesClient = null;
        }
    }

    private void handlePlacesCall(MethodCall call, MethodChannel.Result result) {
        if (placesClient == null) {
            result.error("PLACES_NOT_CONFIGURED", "Places SDK não inicializado.", null);
            return;
        }
        switch (call.method) {
            case "searchNearby":
                searchNearby(call, result);
                break;
            case "searchByText":
                searchByText(call, result);
                break;
            case "fetchPlace":
                fetchPlace(call, result);
                break;
            default:
                result.notImplemented();
        }
    }

    private void searchNearby(MethodCall call, MethodChannel.Result result) {
        CircularBounds area = areaFrom(call);
        SearchNearbyRequest request = SearchNearbyRequest.builder(area, SEARCH_FIELDS)
                .setIncludedTypes(SPORTS_TYPES)
                .setMaxResultCount(20)
                .build();
        placesClient.searchNearby(request)
                .addOnSuccessListener(response -> result.success(placesToMaps(response.getPlaces(), true)))
                .addOnFailureListener(error -> result.error("PLACES_NEARBY_ERROR", error.getMessage(), null));
    }

    private void searchByText(MethodCall call, MethodChannel.Result result) {
        String query = call.argument("query");
        if (query == null || query.trim().isEmpty()) {
            searchNearby(call, result);
            return;
        }
        SearchByTextRequest request = SearchByTextRequest
                .builder(query.trim(), SEARCH_FIELDS)
                .setLocationBias(areaFrom(call))
                .setRegionCode("BR")
                .setMaxResultCount(20)
                .build();
        placesClient.searchByText(request)
                .addOnSuccessListener(response -> result.success(placesToMaps(response.getPlaces(), true)))
                .addOnFailureListener(error -> result.error("PLACES_TEXT_ERROR", error.getMessage(), null));
    }

    private void fetchPlace(MethodCall call, MethodChannel.Result result) {
        String placeId = call.argument("placeId");
        if (placeId == null || placeId.isEmpty()) {
            result.error("PLACE_ID_REQUIRED", "Place ID ausente.", null);
            return;
        }
        FetchPlaceRequest request = FetchPlaceRequest.builder(placeId, DETAIL_FIELDS).build();
        placesClient.fetchPlace(request)
                .addOnSuccessListener(response -> result.success(placeToMap(response.getPlace())))
                .addOnFailureListener(error -> result.error("PLACE_DETAILS_ERROR", error.getMessage(), null));
    }

    private CircularBounds areaFrom(MethodCall call) {
        Number latitude = call.argument("latitude");
        Number longitude = call.argument("longitude");
        Number radius = call.argument("radius");
        double lat = latitude == null ? -29.98 : latitude.doubleValue();
        double lng = longitude == null ? -51.18 : longitude.doubleValue();
        double radiusMeters = radius == null ? 30000 : radius.doubleValue();
        radiusMeters = Math.max(1000, Math.min(50000, radiusMeters));
        return CircularBounds.newInstance(new LatLng(lat, lng), radiusMeters);
    }

    private List<Map<String, Object>> placesToMaps(List<Place> places, boolean filterSports) {
        List<Map<String, Object>> mapped = new ArrayList<>();
        for (Place place : places) {
            if (!filterSports || isSportsPlace(place)) {
                mapped.add(placeToMap(place));
            }
        }
        return mapped;
    }

    private boolean isSportsPlace(Place place) {
        List<String> types = place.getPlaceTypes();
        if (types != null) {
            for (String type : types) {
                if (SPORTS_TYPES.contains(type)) return true;
            }
        }
        if (containsSportsKeyword(place.getDisplayName())) return true;
        if (containsSportsKeyword(place.getFormattedAddress())) return true;
        if (containsSportsKeyword(place.getPrimaryType())) return true;
        return containsSportsKeyword(place.getPrimaryTypeDisplayName());
    }

    private boolean containsSportsKeyword(Object value) {
        if (value == null) return false;
        String normalized = Normalizer
                .normalize(value.toString(), Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT);
        return normalized.contains("quadra")
                || normalized.contains("esport")
                || normalized.contains("ginásio")
                || normalized.contains("ginasio")
                || normalized.contains("arena")
                || normalized.contains("athletic")
                || normalized.contains("sports")
                || normalized.contains("sport")
                || normalized.contains("soccer")
                || normalized.contains("ball")
                || normalized.contains("futsal")
                || normalized.contains("futebol")
                || normalized.contains("society")
                || normalized.contains("vôlei")
                || normalized.contains("volei")
                || normalized.contains("beach tennis")
                || normalized.contains("tênis")
                || normalized.contains("tenis")
                || normalized.contains("padel")
                || normalized.contains("poliesportiva");
    }

    private Map<String, Object> placeToMap(Place place) {
        Map<String, Object> value = new HashMap<>();
        put(value, "placeId", place.getId());
        put(value, "name", place.getDisplayName());
        put(value, "formattedAddress", place.getFormattedAddress());
        put(value, "primaryType", place.getPrimaryType());
        put(value, "primaryTypeDisplayName", place.getPrimaryTypeDisplayName());
        put(value, "rating", place.getRating());
        put(value, "userRatingCount", place.getUserRatingCount());
        put(value, "phone", place.getNationalPhoneNumber());
        put(value, "businessStatus",
                place.getBusinessStatus() == null ? null : place.getBusinessStatus().name());

        LatLng location = place.getLocation();
        if (location != null) {
            value.put("latitude", location.latitude);
            value.put("longitude", location.longitude);
        }
        Uri website = place.getWebsiteUri();
        Uri googleMaps = place.getGoogleMapsUri();
        put(value, "websiteUrl", website == null ? null : website.toString());
        put(value, "googleMapsUrl", googleMaps == null ? null : googleMaps.toString());
        OpeningHours openingHours = place.getOpeningHours();
        if (openingHours != null) {
            value.put("openingHours", openingHours.getWeekdayText());
        }
        return value;
    }

    private void put(Map<String, Object> map, String key, Object value) {
        if (value != null) map.put(key, value);
    }
}

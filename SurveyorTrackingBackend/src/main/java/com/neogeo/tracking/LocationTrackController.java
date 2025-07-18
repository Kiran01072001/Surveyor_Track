package com.neogeo.tracking;

import java.time.Instant;
import java.util.Base64;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.neogeo.tracking.dto.LiveLocationMessage;
import com.neogeo.tracking.model.LocationTrack;
import com.neogeo.tracking.model.Surveyor;
import com.neogeo.tracking.repository.LocationTrackRepository;
import com.neogeo.tracking.service.*;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import io.swagger.v3.oas.annotations.*;
import io.swagger.v3.oas.annotations.media.*;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api")
@Tag(name = "Location Tracking", description = "APIs for tracking surveyor locations")
public class LocationTrackController {

    private final SimpMessagingTemplate messagingTemplate;
    private final LocationTrackRepository repository;
    private final SurveyorService surveyorService;
    private final TracingService tracingService;
    private final ObjectMapper objectMapper;
    private final LocationTrackService locationTrackService;

    @Autowired
    public LocationTrackController(SimpMessagingTemplate messagingTemplate,
                                 LocationTrackRepository repository,
                                 SurveyorService surveyorService,
                                 TracingService tracingService,
                                 LocationTrackService locationTrackService) {
        this.messagingTemplate = messagingTemplate;
        this.repository = repository;
        this.surveyorService = surveyorService;
        this.tracingService = tracingService;
        this.locationTrackService = locationTrackService;
        this.objectMapper = new ObjectMapper()
            .registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule())
            .configure(com.fasterxml.jackson.databind.SerializationFeature.WRITE_DATES_AS_TIMESTAMPS, false);
    }

    @Operation(summary = "Filter surveyors")
    @GetMapping("/surveyors/filter")
    public List<Surveyor> filterSurveyors(
            @Parameter(description = "City to filter by") @RequestParam(required = false) String city,
            @Parameter(description = "Project to filter by") @RequestParam(required = false) String project,
            @Parameter(description = "Online status to filter by") @RequestParam(required = false) String status) {
        return locationTrackService.filterSurveyorsExcludingAdmin(city, project, status);
    }

    @Operation(summary = "Get latest location")
    @GetMapping("/location/{surveyorId}/latest")
    public LocationTrack getLatestLocation(
            @Parameter(description = "ID of the surveyor") @PathVariable String surveyorId) {
        return locationTrackService.getLatestLocation(surveyorId);
    }

    @Operation(summary = "Get location history")
    @GetMapping("/location/{surveyorId}/track")
    public ResponseEntity<Page<LocationTrack>> getTrackHistory(
            @PathVariable String surveyorId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant start,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant end,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "1000") int size) {
        
        if (start.isAfter(end)) {
            return ResponseEntity.badRequest().build();
        }

        Pageable pageable = PageRequest.of(page, size);
        Page<LocationTrack> tracks = locationTrackService.getTrackHistoryPaged(surveyorId, start, end, pageable);
        return tracks.isEmpty() ? ResponseEntity.noContent().build() : ResponseEntity.ok(tracks);
    }

    @GetMapping("/surveyors/status")
    public Map<String, String> getSurveyorStatus() {
        return locationTrackService.getSurveyorStatusesExcludingAdmin();
    }

    @Operation(summary = "Update live location")
    @PostMapping("/live/location")
    public ResponseEntity<String> publishLiveLocation(
            @RequestBody LiveLocationMessage message,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        
        return tracingService.traceGpsOperation("location-update", message.getSurveyorId(), 1, () -> {
            if (!validateAuth(authHeader)) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Invalid credentials");
            }

            try {
                broadcastLocation(message);
                saveLocation(message);
                return ResponseEntity.ok("Location updated");
            } catch (JsonProcessingException e) {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Processing error");
            }
        });
    }

    private boolean validateAuth(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Basic ")) return false;
        
        try {
            String[] credentials = new String(Base64.getDecoder().decode(
                authHeader.substring("Basic ".length()))).split(":", 2);
            return credentials.length == 2 && 
                   surveyorService.authenticateSurveyor(credentials[0], credentials[1]);
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private void broadcastLocation(LiveLocationMessage message) throws JsonProcessingException {
        String json = objectMapper.writeValueAsString(message);
        messagingTemplate.convertAndSend("/topic/location/" + message.getSurveyorId(), json);
    }

    private void saveLocation(LiveLocationMessage message) {
        repository.save(new LocationTrack(
            message.getSurveyorId(),
            message.getLatitude(),
            message.getLongitude(),
            message.getTimestamp() != null ? message.getTimestamp() : Instant.now(),
            null
        ));
    }
}
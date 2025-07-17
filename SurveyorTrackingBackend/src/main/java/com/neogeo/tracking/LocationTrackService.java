package com.neogeo.tracking;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.neogeo.tracking.model.LocationTrack;
import com.neogeo.tracking.model.Surveyor;
import com.neogeo.tracking.repository.LocationTrackRepository;
import com.neogeo.tracking.repository.SurveyorRepository;
import com.neogeo.tracking.service.SurveyorService;

@Service
public class LocationTrackService {

    private static final int OFFLINE_THRESHOLD_MINUTES = 5;

    private final LocationTrackRepository locationTrackRepository;
    private final SurveyorRepository surveyorRepository;
    private final SurveyorService surveyorService;

    @Autowired
    public LocationTrackService(LocationTrackRepository locationTrackRepository,
                              SurveyorRepository surveyorRepository,
                              SurveyorService surveyorService) {
        this.locationTrackRepository = locationTrackRepository;
        this.surveyorRepository = surveyorRepository;
        this.surveyorService = surveyorService;
    }

    public List<Surveyor> getAllSurveyorsExcludingAdmin() {
        return surveyorRepository.findAll().stream()
            .filter(this::isValidSurveyor)
            .collect(Collectors.toList());
    }

    public Map<String, String> getSurveyorStatusesExcludingAdmin() {
        Instant now = Instant.now();
        Instant threshold = now.minus(OFFLINE_THRESHOLD_MINUTES, ChronoUnit.MINUTES);
        
        return getAllSurveyorsExcludingAdmin().stream()
            .collect(Collectors.toMap(
                Surveyor::getId,
                surveyor -> determineStatus(surveyor.getId(), threshold)
            ));
    }

    public List<Surveyor> filterSurveyorsExcludingAdmin(String city, String project, String status) {
        List<Surveyor> surveyors = findSurveyorsByFilters(city, project);
        return surveyors.stream()
            .filter(this::isValidSurveyor)
            .peek(this::logSurveyorDetails)
            .collect(Collectors.toList());
    }

    public LocationTrack getLatestLocation(String surveyorId) {
        return locationTrackRepository
            .findTopBySurveyorIdOrderByTimestampDesc(surveyorId)
            .orElse(null);
    }

    public List<LocationTrack> getTrackHistory(String surveyorId, Instant start, Instant end) {
        validateTimeRange(start, end);
        
        List<LocationTrack> results = fetchLocationTracks(surveyorId, start, end);
        logResults(results);
        return results;
    }

    private boolean isValidSurveyor(Surveyor surveyor) {
        return surveyor.getId() != null &&
               !surveyor.getId().toLowerCase().contains("admin") &&
               (surveyor.getUsername() == null || !surveyor.getUsername().toLowerCase().contains("admin"));
    }

    private String determineStatus(String surveyorId, Instant threshold) {
        LocationTrack lastLocation = getLatestLocation(surveyorId);
        boolean isLocationActive = lastLocation != null && 
                                 lastLocation.getTimestamp().isAfter(threshold);
        boolean isActiveFromStatus = surveyorService.isSurveyorOnline(surveyorId);
        
        return (isLocationActive || isActiveFromStatus) ? "Online" : "Offline";
    }

    private List<Surveyor> findSurveyorsByFilters(String city, String project) {
        if (city != null && project != null) {
            return surveyorRepository.findByCityAndProjectName(city, project);
        } else if (city != null) {
            return surveyorRepository.findByCity(city);
        } else if (project != null) {
            return surveyorRepository.findByProjectName(project);
        }
        return surveyorRepository.findAll();
    }

    private void logSurveyorDetails(Surveyor surveyor) {
        System.out.printf("Surveyor: ID=%s, Name=%s, City=%s, Project=%s%n",
            surveyor.getId(), surveyor.getName(), surveyor.getCity(), surveyor.getProjectName());
    }

    private void validateTimeRange(Instant start, Instant end) {
        if (start != null && end != null && start.isAfter(end)) {
            throw new IllegalArgumentException("Start time must be before end time");
        }
    }

    private List<LocationTrack> fetchLocationTracks(String surveyorId, Instant start, Instant end) {
        if (start != null && end != null) {
            return locationTrackRepository.findBySurveyorIdAndTimestampBetweenOrderByTimestampAsc(
                surveyorId, start, end);
        } else if (start != null) {
            return locationTrackRepository.findBySurveyorIdAndTimestampAfterOrderByTimestampAsc(
                surveyorId, start);
        } else if (end != null) {
            return locationTrackRepository.findBySurveyorIdAndTimestampBeforeOrderByTimestampAsc(
                surveyorId, end);
        }
        return locationTrackRepository.findBySurveyorIdOrderByTimestampAsc(surveyorId);
    }

    private void logResults(List<LocationTrack> results) {
        System.out.printf("Query returned %d records%n", results.size());
        results.stream().limit(3).forEach(track ->
            System.out.printf("  %s at %s -> (%.6f, %.6f)%n",
                track.getSurveyorId(), track.getTimestamp(),
                track.getLatitude(), track.getLongitude())
        );
    }
}
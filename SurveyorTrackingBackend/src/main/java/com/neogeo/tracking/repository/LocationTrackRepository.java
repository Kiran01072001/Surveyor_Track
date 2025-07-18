package com.neogeo.tracking.repository;

import java.time.Instant;  // Changed from LocalDateTime
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.neogeo.tracking.model.LocationTrack;

@Repository
public interface LocationTrackRepository extends JpaRepository<LocationTrack, Long> {
    
    // Find latest location for a surveyor
    Optional<LocationTrack> findTopBySurveyorIdOrderByTimestampDesc(String surveyorId);
    
    // Find all locations for a surveyor ordered by timestamp
    List<LocationTrack> findBySurveyorIdOrderByTimestampAsc(String surveyorId);
    
    // Find locations within date range (changed to Instant)
    List<LocationTrack> findBySurveyorIdAndTimestampBetweenOrderByTimestampAsc(
        String surveyorId, Instant start, Instant end);  // Changed parameter type
    
    // Find locations after a specific date (changed to Instant)
    List<LocationTrack> findBySurveyorIdAndTimestampAfterOrderByTimestampAsc(
        String surveyorId, Instant start);  // Changed parameter type
    
    // Find locations before a specific date (changed to Instant)
    List<LocationTrack> findBySurveyorIdAndTimestampBeforeOrderByTimestampAsc(
        String surveyorId, Instant end);  // Changed parameter type
    
    // Custom query with Instant parameters
    @Query("SELECT lt FROM LocationTrack lt WHERE lt.surveyorId = :surveyorId " +
           "AND (:start IS NULL OR lt.timestamp >= :start) " +
           "AND (:end IS NULL OR lt.timestamp <= :end) " +
           "ORDER BY lt.timestamp ASC")
    List<LocationTrack> findLocationsByDateRange(
        @Param("surveyorId") String surveyorId,
        @Param("start") Instant start,  // Changed type
        @Param("end") Instant end);     // Changed type
    
    // Count locations (unchanged)
    @Query("SELECT COUNT(lt) FROM LocationTrack lt WHERE lt.surveyorId = :surveyorId")
    long countBySurveyorId(@Param("surveyorId") String surveyorId);
    
    // Find all surveyor IDs (unchanged)
    @Query("SELECT DISTINCT lt.surveyorId FROM LocationTrack lt")
    List<String> findAllSurveyorIds();

    // Find locations within date range (changed to Instant) with pagination
    Page<LocationTrack> findBySurveyorIdAndTimestampBetweenOrderByTimestampAsc(
        String surveyorId, Instant start, Instant end, Pageable pageable);
}
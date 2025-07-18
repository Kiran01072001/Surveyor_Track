package com.neogeo.tracking.controller;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.neogeo.tracking.model.Surveyor;
import com.neogeo.tracking.service.SurveyorService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/surveyors")
@Tag(name = "Surveyor Management", description = "APIs for managing surveyors and authentication")
public class SurveyorController {

    private final SurveyorService surveyorService;

    public SurveyorController(SurveyorService surveyorService) {
        this.surveyorService = surveyorService;
    }

    @Operation(summary = "Get all surveyors", description = "Retrieves a list of all registered surveyors with online status")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved surveyors",
            content = @Content(mediaType = "application/json", 
            schema = @Schema(implementation = Surveyor.class)))
    })
    @GetMapping
    public ResponseEntity<List<Surveyor>> getAllSurveyors() {
        List<Surveyor> surveyors = surveyorService.getAllSurveyorsWithStatus();
        return ResponseEntity.ok(surveyors);
    }

    @Operation(summary = "Create or update surveyor", 
              description = "Creates a new surveyor or updates an existing one. Password is hashed before storage.")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Surveyor created/updated successfully"),
        @ApiResponse(responseCode = "400", description = "Invalid input data")
    })
    @PostMapping
    public ResponseEntity<Surveyor> saveSurveyor(
            @Parameter(description = "Surveyor details", required = true)
            @RequestBody Surveyor surveyor) {
        
        Surveyor savedSurveyor = surveyorService.saveOrUpdateSurveyor(surveyor);
        return ResponseEntity.ok(savedSurveyor);
    }

    @Operation(summary = "Authenticate surveyor", 
              description = "Validates surveyor credentials and returns authentication status with surveyor details")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Authentication successful"),
        @ApiResponse(responseCode = "401", description = "Invalid credentials"),
        @ApiResponse(responseCode = "404", description = "Surveyor not found")
    })
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> authenticateSurveyor(
            @Parameter(description = "Login credentials (username and password)", required = true)
            @RequestBody Map<String, String> credentials) {
        
        Map<String, Object> response = surveyorService.authenticateAndGetResponse(
            credentials.get("username"),
            credentials.get("password")
        );
        
        return ResponseEntity.status((int) response.get("status"))
               .body(response);
    }
    
    @Operation(summary = "Check username availability", 
              description = "Checks if a username is available for registration")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Availability check completed")
    })
    @GetMapping("/check-username")
    public ResponseEntity<Map<String, Boolean>> checkUsernameAvailability(
            @Parameter(description = "Username to check", required = true)
            @RequestParam String username) {
        
        boolean isAvailable = surveyorService.isUsernameAvailable(username);
        return ResponseEntity.ok(Map.of("available", isAvailable));
    }
    
    @Operation(summary = "Update surveyor activity", 
              description = "Updates the last activity timestamp for a surveyor")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Activity updated"),
        @ApiResponse(responseCode = "404", description = "Surveyor not found")
    })
    @PostMapping("/{id}/activity")
    public ResponseEntity<Void> updateActivity(
            @Parameter(description = "Surveyor ID", required = true)
            @PathVariable String id) {
        
        surveyorService.updateSurveyorActivity(id);
        return ResponseEntity.ok().build();
    }

    @Operation(summary = "Get surveyor status", 
              description = "Returns the online/offline status of a surveyor")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Status retrieved"),
        @ApiResponse(responseCode = "404", description = "Surveyor not found")
    })
    @GetMapping("/{id}/status")
    public ResponseEntity<Map<String, Boolean>> getSurveyorStatus(
            @Parameter(description = "Surveyor ID", required = true)
            @PathVariable String id) {
        
        boolean isOnline = surveyorService.isSurveyorOnline(id);
        return ResponseEntity.ok(Map.of("online", isOnline));
    }

    @Operation(summary = "Delete surveyor", description = "Deletes a surveyor by ID")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Surveyor deleted successfully"),
        @ApiResponse(responseCode = "404", description = "Surveyor not found")
    })
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSurveyor(
            @Parameter(description = "Surveyor ID", required = true)
            @PathVariable String id) {
        boolean deleted = surveyorService.deleteSurveyorById(id);
        if (deleted) {
            return ResponseEntity.ok().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    @Operation(summary = "Get all distinct cities", 
              description = "Retrieves a list of all distinct cities from surveyors")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved cities")
    })
    @GetMapping("/cities")
    public ResponseEntity<List<String>> getAllCities() {
        List<String> cities = surveyorService.getAllDistinctCities();
        return ResponseEntity.ok(cities);
    }

    @Operation(summary = "Get all distinct projects", 
              description = "Retrieves a list of all distinct project names from surveyors")
    @ApiResponses(value = {
        @ApiResponse(responseCode = "200", description = "Successfully retrieved projects")
    })
    @GetMapping("/projects")
    public ResponseEntity<List<String>> getAllProjects() {
        List<String> projects = surveyorService.getAllDistinctProjects();
        return ResponseEntity.ok(projects);
    }
}
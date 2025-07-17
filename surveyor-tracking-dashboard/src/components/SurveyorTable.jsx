import React from 'react';
import {
  Box,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Tooltip,
  Typography,
  Chip
} from '@mui/material';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';

const SurveyorTable = ({ surveyors, onEdit, onDelete }) => {
  if (!surveyors || surveyors.length === 0) {
    return (
      <Box sx={{
        textAlign: 'center',
        p: 4,
        mt: 3,
        background: 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)',
        borderRadius: '12px',
        border: '2px dashed #cbd5e1'
      }}>
        <div style={{ fontSize: '4rem', marginBottom: '1rem', opacity: 0.5 }}>👥</div>
        <Typography variant="h6" sx={{ color: '#374151', fontWeight: 600, mb: 1 }}>
          No Surveyors Found
        </Typography>
        <Typography color="textSecondary" sx={{ fontSize: '0.95rem' }}>
          Click the "Add Surveyor" button to get started with your surveyor management.
        </Typography>
      </Box>
    );
  }

  return (
    <TableContainer sx={{
      borderRadius: '12px',
      boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
      overflow: 'hidden',
      background: '#fff'
    }}>
      <Table sx={{ minWidth: 650 }} aria-label="surveyors table">
        <TableHead sx={{ background: 'linear-gradient(90deg, #f1f5f9 0%, #e0e7ef 100%)' }}>
          <TableRow>
            <TableCell sx={{ fontWeight: 700, color: '#374151', textTransform: 'uppercase', fontSize: '0.95rem' }}>ID</TableCell>
            <TableCell sx={{ fontWeight: 700, color: '#374151', textTransform: 'uppercase', fontSize: '0.95rem' }}>Name</TableCell>
            <TableCell sx={{ fontWeight: 700, color: '#374151', textTransform: 'uppercase', fontSize: '0.95rem' }}>Username</TableCell>
            <TableCell sx={{ fontWeight: 700, color: '#374151', textTransform: 'uppercase', fontSize: '0.95rem' }}>City</TableCell>
            <TableCell sx={{ fontWeight: 700, color: '#374151', textTransform: 'uppercase', fontSize: '0.95rem' }}>Project</TableCell>
            <TableCell align="center" sx={{ fontWeight: 700, color: '#374151', textTransform: 'uppercase', fontSize: '0.95rem' }}>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {surveyors.map((surveyor) => (
            <TableRow key={surveyor.id || surveyor._id} hover>
              <TableCell sx={{ fontWeight: 600, color: '#1e40af' }}>{surveyor.id}</TableCell>
              <TableCell sx={{ fontWeight: 500 }}>{surveyor.name}</TableCell>
              <TableCell sx={{ color: '#6b7280' }}>{surveyor.username || 'N/A'}</TableCell>
              <TableCell>
                <Chip label={surveyor.city || 'N/A'} size="small" sx={{ background: '#3b82f6', color: '#fff', fontWeight: 500 }} />
              </TableCell>
              <TableCell>
                <Chip label={surveyor.projectName || 'No Project'} size="small" sx={{ background: '#10b981', color: '#fff', fontWeight: 500 }} />
              </TableCell>
              <TableCell align="center">
                <Box sx={{ display: 'flex', justifyContent: 'center', gap: 1 }}>
                  <Tooltip title="Edit Surveyor" arrow>
                    <IconButton onClick={() => onEdit(surveyor)} sx={{ color: '#f59e42' }}>
                      <EditIcon />
                    </IconButton>
                  </Tooltip>
                  <Tooltip title="Delete Surveyor" arrow>
                    <IconButton onClick={() => onDelete(surveyor.id || surveyor._id)} sx={{ color: '#ef4444' }}>
                      <DeleteIcon />
                    </IconButton>
                  </Tooltip>
                </Box>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
};

export default SurveyorTable; 
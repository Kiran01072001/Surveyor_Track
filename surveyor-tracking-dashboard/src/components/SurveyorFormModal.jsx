import React, { useState, useEffect } from 'react';
import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    TextField,
    IconButton,
    InputAdornment,
    Typography,
    Box,
    CircularProgress,
    createTheme, // To create a custom theme
    ThemeProvider, // To apply the theme
    styled, // To create custom styled components
    Divider,
    Paper
} from '@mui/material';
import VisibilityIcon from '@mui/icons-material/Visibility';
import VisibilityOffIcon from '@mui/icons-material/VisibilityOff';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import EditIcon from '@mui/icons-material/Edit';
import CloseIcon from '@mui/icons-material/Close';

// Enhanced theme with better colors and styling
const dialogTheme = createTheme({
    palette: {
        primary: {
            main: '#2563eb', // Professional blue
            light: '#3b82f6',
            dark: '#1d4ed8',
            contrastText: '#ffffff',
        },
        secondary: {
            main: '#64748b',
            light: '#94a3b8',
            dark: '#475569',
        },
    },
    typography: {
        h6: {
            fontWeight: 700,
        },
        subtitle1: {
            fontWeight: 600,
        },
    },
});

// Enhanced styled text field with better visual design
const StyledTextField = styled(TextField)(({ theme }) => ({
    '& .MuiOutlinedInput-root': {
        borderRadius: '12px',
        backgroundColor: '#f8fafc',
        transition: 'all 0.3s ease',
        '&:hover': {
            backgroundColor: '#f1f5f9',
            transform: 'translateY(-1px)',
            boxShadow: '0 4px 12px rgba(37, 99, 235, 0.1)',
        },
        '&.Mui-focused': {
            backgroundColor: '#ffffff',
            transform: 'translateY(-2px)',
            boxShadow: '0 8px 25px rgba(37, 99, 235, 0.15)',
        },
        '& .MuiOutlinedInput-notchedOutline': {
            borderColor: '#e2e8f0',
            borderWidth: '2px',
            transition: 'all 0.3s ease',
        },
        '&:hover .MuiOutlinedInput-notchedOutline': {
            borderColor: theme.palette.primary.light,
        },
        '&.Mui-focused .MuiOutlinedInput-notchedOutline': {
            borderColor: theme.palette.primary.main,
            borderWidth: '2px',
        },
    },
    '& .MuiInputLabel-outlined': {
        color: '#64748b',
        fontWeight: 500,
        '&.Mui-focused': {
            color: theme.palette.primary.main,
            fontWeight: 600,
        },
    },
    '& .MuiInputBase-input': {
        fontWeight: 500,
        color: '#1e293b',
    },
}));

// Enhanced gradient border button
const GradientBorderButton = styled(Button)(({ theme }) => ({
    position: 'relative',
    padding: '12px 32px',
    border: '2px solid transparent',
    backgroundClip: 'padding-box',
    borderRadius: '12px',
    color: theme.palette.primary.main,
    fontWeight: 600,
    fontSize: '0.95rem',
    textTransform: 'none',
    transition: 'all 0.3s ease',
    '&:before': {
        content: '""',
        position: 'absolute',
        top: 0, right: 0, bottom: 0, left: 0,
        zIndex: -1,
        margin: '-2px',
        borderRadius: 'inherit',
        background: 'linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%)',
    },
    '&:hover': {
        transform: 'translateY(-2px)',
        boxShadow: '0 8px 25px rgba(37, 99, 235, 0.25)',
    },
}));


const SurveyorFormModal = ({ open, onClose, onSave, surveyor }) => {
    const isEditing = surveyor !== null;
    const initialFormState = { id: '', name: '', city: '', projectName: '', username: '', password: '' };
    
    const [form, setForm] = useState(initialFormState);
    const [showPassword, setShowPassword] = useState(false);
    const [isSaving, setIsSaving] = useState(false);
    const [error, setError] = useState('');

    useEffect(() => {
        if (open) {
            if (isEditing) {
                setForm({ ...surveyor, password: '' });
            } else {
                setForm(initialFormState);
            }
            setError('');
            setIsSaving(false);
        }
    }, [open, surveyor, isEditing]);

    const handleChange = (e) => {
        const { name, value } = e.target;
        setForm(prev => ({ ...prev, [name]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        
        if (!form.id || !form.name || !form.username) {
            setError('ID, Name, and Username are required fields.');
            return;
        }

        setIsSaving(true);
        setError('');

        try {
            const config = (await import('../config')).default;
            const backendUrl = `${config.backendHost}/api/surveyors`;

            const response = await fetch(backendUrl, {
                method: 'POST', // Always use POST as the backend endpoint handles both create and update
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(form),
            });

            if (!response.ok) {
                let errorMessage = 'Failed to save surveyor.';
                try {
                    const errData = await response.json();
                    errorMessage = errData.message || 
                                  errData.error || 
                                  (errData.errors && errData.errors[0]) || 
                                  errorMessage;
                    console.error('Server error details:', errData);
                } catch (parseError) {
                    console.error('Could not parse error response:', parseError);
                }
                throw new Error(errorMessage);
            }

            const savedSurveyor = await response.json();
            console.log('Surveyor saved successfully:', savedSurveyor);
            
            let successMessage;
            if (isEditing) {
                successMessage = `✅ Surveyor Information Updated! ✅

🔄 ${savedSurveyor.name || savedSurveyor.id} was updated successfully! 🎉

📋 Updated Details:
👤 Name: ${savedSurveyor.name}
🏙️ City: ${savedSurveyor.city || "Not specified"}
📁 Project: ${savedSurveyor.projectName || "Not specified"}

✨ Changes have been saved to the system`;
            } else {
                successMessage = `🎉 New surveyor ${savedSurveyor.name || savedSurveyor.id} was added successfully! ✅\n\n📱 IMPORTANT: Please note down these login credentials for mobile app access 📱\n👤 Username: ${form.username}\n🔑 Password: ${form.password}

📝 Keep this information secure! 📝`;
            }
            
            alert(successMessage);
            onSave();
        } catch (err) {
            console.error('Error saving surveyor:', err);
            setError(err.message || 'Failed to save surveyor. Please try again.');
        } finally {
            setIsSaving(false);
        }
    };

    return (
        <ThemeProvider theme={dialogTheme}>
            <Dialog 
                open={open} 
                onClose={onClose} 
                fullWidth 
                maxWidth="md" 
                component="form" 
                onSubmit={handleSubmit} 
                PaperProps={{ 
                    sx: { 
                        borderRadius: '20px',
                        background: 'linear-gradient(135deg, #ffffff 0%, #f8fafc 100%)',
                        boxShadow: '0 25px 50px rgba(0,0,0,0.15)',
                        border: '1px solid rgba(37, 99, 235, 0.1)',
                        overflow: 'hidden'
                    } 
                }}
            >
                {/* Enhanced Header */}
                <Box sx={{
                    background: 'linear-gradient(135deg, #1e40af 0%, #3b82f6 100%)',
                    color: '#ffffff',
                    p: 3,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'space-between'
                }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        {isEditing ? (
                            <EditIcon sx={{ fontSize: '2rem' }} />
                        ) : (
                            <PersonAddIcon sx={{ fontSize: '2rem' }} />
                        )}
                        <Typography variant="h5" sx={{ fontWeight: 700, letterSpacing: '0.5px' }}>
                            {isEditing ? 'Edit Surveyor Information' : 'Add New Surveyor'}
                        </Typography>
                    </Box>
                    <IconButton 
                        onClick={onClose} 
                        sx={{ 
                            color: '#ffffff',
                            '&:hover': {
                                backgroundColor: 'rgba(255, 255, 255, 0.1)'
                            }
                        }}
                    >
                        <CloseIcon />
                    </IconButton>
                </Box>

                <DialogContent sx={{ p: 4 }}>
                    {error && (
                        <Paper sx={{ 
                            p: 2, 
                            mb: 3, 
                            background: 'linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%)',
                            border: '1px solid #fecaca',
                            borderRadius: '12px'
                        }}>
                            <Typography color="error" sx={{ fontWeight: 60, display: 'flex', alignItems: 'center', gap: 1 }}>
                                ⚠️ {error}
                            </Typography>
                        </Paper>
                    )}
                    
                    {/* Basic Information Section */}
                    <Box sx={{ mb: 4 }}>
                        <Typography variant="h6" sx={{ 
                            mb: 3, 
                            color: '#1e293b', 
                            fontWeight: 700,
                            display: 'flex',
                            alignItems: 'center',
                            gap: 1
                        }}>
                            📋 Basic Information
                        </Typography>
                        
                        <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 3 }}>
                            <StyledTextField 
                                label="ID *" 
                                name="id" 
                                value={form.id} 
                                onChange={handleChange} 
                                fullWidth 
                                required 
                                disabled={isEditing}
                                helperText="Unique identifier for the surveyor"
                            />
                            <StyledTextField 
                                label="Name *" 
                                name="name" 
                                value={form.name} 
                                onChange={handleChange} 
                                fullWidth 
                                required
                                helperText="Full name of the surveyor"
                            />
                        </Box>
                        
                        <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 3, mt: 3 }}>
                            <StyledTextField 
                                label="City" 
                                name="city" 
                                value={form.city} 
                                onChange={handleChange} 
                                fullWidth
                                helperText="City where surveyor operates"
                            />
                            <StyledTextField 
                                label="Project" 
                                name="projectName" 
                                value={form.projectName} 
                                onChange={handleChange} 
                                fullWidth
                                helperText="Project assignment (optional)"
                            />
                        </Box>
                    </Box>

                    {/* Authentication Section */}
                    <Divider sx={{ my: 3, borderColor: '#e2e8f0' }} />
                    
                    <Box>
                        <Typography variant="h6" sx={{ 
                            mb: 3, 
                            color: '#1e293b', 
                            fontWeight: 700,
                            display: 'flex',
                            alignItems: 'center',
                            gap: 1
                        }}>
                            🔐 Authentication Details
                        </Typography>
                        
                        <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 3 }}>
                            <StyledTextField 
                                label="Username *" 
                                name="username" 
                                value={form.username} 
                                onChange={handleChange} 
                                fullWidth 
                                required
                                helperText="Login username for mobile app"
                            />
                            <StyledTextField
                                label={isEditing ? 'New Password' : 'Password'}
                                name="password"
                                type={showPassword ? 'text' : 'password'}
                                value={form.password}
                                onChange={handleChange}
                                fullWidth
                                required={!isEditing}
                                placeholder={isEditing ? 'Leave blank to keep current' : ''}
                                helperText={isEditing ? 'Leave blank to keep current password' : 'Secure password for mobile app access'}
                                InputProps={{
                                    endAdornment: (
                                        <InputAdornment position="end">
                                            <IconButton 
                                                onClick={() => setShowPassword(!showPassword)} 
                                                edge="end"
                                                sx={{ color: '#64748b' }}
                                            >
                                                {showPassword ? <VisibilityOffIcon /> : <VisibilityIcon />}
                                            </IconButton>
                                        </InputAdornment>
                                    ),
                                }}
                            />
                        </Box>
                    </Box>
                </DialogContent>

                {/* Enhanced Actions */}
                <DialogActions sx={{ 
                    p: 3, 
                    background: '#f8fafc',
                    borderTop: '1px solid #e2e8f0'
                }}>
                    <GradientBorderButton onClick={onClose} disabled={isSaving}>
                        Cancel
                    </GradientBorderButton>
                    <Box sx={{ position: 'relative' }}>
                        <Button 
                            type="submit" 
                            variant="contained" 
                            disabled={isSaving}
                            sx={{
                                background: 'linear-gradient(135deg, #1e40af 0%, #3b82f6 100%)',
                                borderRadius: '12px',
                                boxShadow: '0 8px 25px rgba(37, 99, 235, 0.3)',
                                color: 'white',
                                fontWeight: 600,
                                padding: '12px 32px',
                                fontSize: '0.95rem',
                                textTransform: 'none',
                                '&:hover': {
                                    background: 'linear-gradient(135deg, #1d4ed8 0%, #2563eb 100%)',
                                    transform: 'translateY(-2px)',
                                    boxShadow: '0 12px 35px rgba(37, 99, 235, 0.4)',
                                },
                                '&:disabled': {
                                    background: '#94a3b8',
                                    transform: 'none',
                                    boxShadow: 'none',
                                }
                            }}
                        >
                            {isSaving ? 'Saving...' : (isEditing ? 'Update Surveyor' : 'Create Surveyor')}
                        </Button>
                        {isSaving && (
                            <CircularProgress 
                                size={20} 
                                sx={{ 
                                    position: 'absolute', 
                                    top: '50%', 
                                    left: '50%', 
                                    mt: '-10px', 
                                    ml: '-10px',
                                    color: '#ffffff'
                                }} 
                            />
                        )}
                    </Box>
                </DialogActions>
            </Dialog>
        </ThemeProvider>
    );
};

export default SurveyorFormModal;
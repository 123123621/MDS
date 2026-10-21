@echo off
gmx pdb2gmx -f rep.pdb -o rep_gmx.gro -p topol.top -ignh -merge all
pause

@echo off
sobtop.exe lig.mol2
pause

@echo off
chcp 65001
cd %~dp0
perl .\MD07.merge.pl
pause

@echo off
gmx editconf -f merge_gmx.gro -o rep_newbox.gro -c -d 1.0 -bt cubic 
pause

@echo off
gmx solvate -cp rep_newbox.gro -cs spc216.gro -o rep_solv.gro -p merge_topol.top 
pause

@echo off
gmx grompp -f ref.ions.mdp -c rep_solv.gro -p merge_topol.top -o ions.tpr -maxwarn 2
pause

@echo off
gmx genion -s ions.tpr -o solv_ions.gro -p merge_topol.top -pname NA -nname CL -neutral
pause

@echo off
gmx grompp -f ref.em_steep.mdp -c solv_ions.gro -p merge_topol.top -o em_steep.tpr -maxwarn 2
pause

@echo off
gmx mdrun -v -deffnm em_steep -nb gpu
pause

@echo off
gmx grompp -f ref.em_cg.mdp -c em_steep.gro -p merge_topol.top -o em_cg.tpr -maxwarn 2
pause

@echo off
gmx mdrun -v -deffnm em_cg -rdd 2.5 -dds 1.0 -nb cpu -ntmpi 1
pause

@echo off
gmx genrestr -f lig.gro -o posre_lig.itp -fc 1000 1000 1000
pause

title       = OPLS Lysozyme NVT equilibration
define      = -DPOSRES  ; position restrain the protein
; Run parameters
integrator  = md        ; leap-frog integrator
nsteps      = 50000000     ; 2 * 50000 = 100 ps
dt          = 0.002     ; 2 fs
; Output control
nstxout     = 500       ; save coordinates every 1.0 ps
nstvout     = 500       ; save velocities every 1.0 ps
nstenergy   = 500       ; save energies every 1.0 ps
nstlog      = 500       ; update log file every 1.0 ps
; Bond parameters
continuation            = no        ; first dynamics run
constraint_algorithm    = lincs     ; holonomic constraints
constraints             = h-bonds   ; all bonds (even heavy atom-H bonds) constrained
lincs_iter              = 1         ; accuracy of LINCS
lincs_order             = 4         ; also related to accuracy
; Neighborsearching
cutoff-scheme   = Verlet
ns_type         = grid      ; search neighboring grid cells
nstlist         = 10        ; 20 fs, largely irrelevant with Verlet
rcoulomb        = 1.0       ; short-range electrostatic cutoff (in nm)
rvdw            = 1.0       ; short-range van der Waals cutoff (in nm)
; Electrostatics
coulombtype     = PME   ; Particle Mesh Ewald for long-range electrostatics
pme_order       = 4     ; cubic interpolation
fourierspacing  = 0.16  ; grid spacing for FFT
; Temperature coupling is on
tcoupl      = V-rescale             ; modified Berendsen thermostat
tc-grps     = system                ; one coupling groups - more accurate
tau_t       = 0.1                   ; time constant, in ps
ref_t       = 300                   ; reference temperature, one for each group, in K
; Pressure coupling is off
pcoupl      = no        ; no pressure coupling in NVT
; Periodic boundary conditions
pbc     = xyz           ; 3-D PBC
; Dispersion correction
DispCorr    = EnerPres  ; account for cut-off vdW scheme
; Velocity generation
gen_vel     = yes       ; assign velocities from Maxwell distribution
gen_temp    = 300       ; temperature for Maxwell distribution
gen_seed    = -1        ; generate a random seed


title       = OPLS Lysozyme NPT equilibration
define      = -DPOSRES  ; position restrain the protein
; Run parameters
integrator  = md        ; leap-frog integrator
nsteps      = 1000000   ; 50000 = 100 ps
dt          = 0.002     ; 2 fs
; Output control
nstxout     = 500       ; save coordinates every 1.0 ps
nstvout     = 500       ; save velocities every 1.0 ps
nstenergy   = 500       ; save energies every 1.0 ps
nstlog      = 500       ; update log file every 1.0 ps
; Bond parameters
continuation            = yes       ; Restarting after NVT
constraint_algorithm    = lincs     ; holonomic constraints
constraints             = h-bonds   ; all bonds (even heavy atom-H bonds) constrained
lincs_iter              = 1         ; accuracy of LINCS
lincs_order             = 4         ; also related to accuracy
; Neighborsearching
cutoff-scheme   = Verlet
ns_type         = grid      ; search neighboring grid cells
nstlist         = 10        ; 20 fs, largely irrelevant with Verlet scheme
rcoulomb        = 1.0       ; short-range electrostatic cutoff (in nm)
rvdw            = 1.0       ; short-range van der Waals cutoff (in nm)
; Electrostatics
coulombtype     = PME       ; Particle Mesh Ewald for long-range electrostatics
pme_order       = 4         ; cubic interpolation
fourierspacing  = 0.16      ; grid spacing for FFT
; Temperature coupling is on
tcoupl      = V-rescale             ; modified Berendsen thermostat
tc-grps     = Protein Non-Protein   ; two coupling groups - more accurate
tau_t       = 0.1     0.1           ; time constant, in ps
ref_t       = 300     300           ; reference temperature, one for each group, in K
; Pressure coupling is on
pcoupl              = berendsen             ; Pressure coupling on in NPT
pcoupltype          = isotropic             ; uniform scaling of box vectors
tau_p               = 2.0                   ; time constant, in ps
ref_p               = 1.0                   ; reference pressure, in bar
compressibility     = 4.5e-5                ; isothermal compressibility of water, bar^-1
refcoord_scaling    = com
; Periodic boundary conditions
pbc     = xyz       ; 3-D PBC
; Dispersion correction
DispCorr    = EnerPres  ; account for cut-off vdW scheme
; Velocity generation
gen_vel     = no        ; Velocity generation is off


title       = OPLS Lysozyme MD simulation
; Run parameters
integrator  = md        ; leap-frog integrator
nsteps      = 50000000 ; 2 * 500000 = 1000 ps (1 ns)
dt          = 0.002     ; 2 fs
; Output control
nstxout             = 15000      ; save coordinates every 30.0 ps
nstvout             = 15000      ; save velocities every 30.0 ps
nstenergy           = 15000      ; save energies every 30.0 ps
nstlog              = 15000      ; update log file every 30.0 ps
nstxout-compressed  = 15000      ; save compressed coordinates every 10.0 ps
                                ; nstxout-compressed replaces nstxtcout
compressed-x-grps   = System    ; replaces xtc-grps
; Bond parameters
continuation            = yes       ; Restarting after NPT
constraint_algorithm    = lincs     ; holonomic constraints
constraints             = h-bonds   ; all bonds (even heavy atom-H bonds) constrained
lincs_iter              = 1         ; accuracy of LINCS
lincs_order             = 4         ; also related to accuracy
; Neighborsearching
cutoff-scheme   = Verlet
ns_type         = grid      ; search neighboring grid cells
nstlist         = 10        ; 20 fs, largely irrelevant with Verlet scheme
rcoulomb        = 1.0       ; short-range electrostatic cutoff (in nm)
rvdw            = 1.0       ; short-range van der Waals cutoff (in nm)
; Electrostatics
coulombtype     = PME       ; Particle Mesh Ewald for long-range electrostatics
pme_order       = 4         ; cubic interpolation
fourierspacing  = 0.16      ; grid spacing for FFT
; Temperature coupling is on
tcoupl      = V-rescale             ; modified Berendsen thermostat
tc-grps     = Protein Non-Protein   ; two coupling groups - more accurate
tau_t       = 0.1     0.1           ; time constant, in ps
ref_t       = 300     300           ; reference temperature, one for each group, in K
; Pressure coupling is on
pcoupl              = berendsen             ; Pressure coupling on in NPT
pcoupltype          = isotropic             ; uniform scaling of box vectors
tau_p               = 2.0                   ; time constant, in ps
ref_p               = 1.0                   ; reference pressure, in bar
compressibility     = 4.5e-5                ; isothermal compressibility of water, bar^-1
; Periodic boundary conditions
pbc     = xyz       ; 3-D PBC
; Dispersion correction
DispCorr    = EnerPres  ; account for cut-off vdW scheme
; Velocity generation
gen_vel     = no        ; Velocity generation is off



gmx make_ndx -f md_0_1.tpr -o index_combined.ndx


gmx trjconv -s md_0_1.tpr -f md_0_1.xtc -o md_nojump.xtc -pbc nojump

gmx trjconv -s md_0_1.tpr -f md_nojump.xtc -o md_cluster.xtc -pbc cluster -n index_combined.ndx

gmx trjconv -s md_0_1.tpr -f md_cluster.xtc -o md_fit.xtc -fit rot+trans -n index_combined.ndx

gmx rms -s md_0_1.tpr -f md_fit.xtc -o rmsd_protein.xvg -n index_combined.ndx -tu ns

gmx rms -s md_0_1.tpr -f md_fit.xtc -o rmsd_complex.xvg -n index_combined.ndx -tu ns


gmx rms -s md_0_1.tpr -f md_fit.xtc -o rmsd_lig.xvg -n index_combined.ndx -tu ns

@echo off
gmx rmsf -s md_0_1.tpr -f md_fit.xtc -res -n index_combined.ndx -o rmsf_protein.xvg
pause

@echo off
gmx gyrate -s md_0_1.tpr -f md_fit.xtc -o gyrate.xvg -tu ns
pause

@echo off
gmx sasa -s md_0_1.tpr -f md_fit.xtc -o sasa.xvg -tu ns
pause


@echo off
gmx hbond -s md_0_1.tpr -f md_fit.xtc -n index_combined.ndx -num hbond.xvg -tu ns
pause



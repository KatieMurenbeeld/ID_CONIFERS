#!/usr/bin/env bash

SRCDIR=/glade/work/katiem/git/spt_logging
cd ${SRCDIR}
GITHASH1=`git log -n 1 --format=%h`
cd src/fates
GITHASH2=`git log -n 1 --format=%h`

#SETUP_CASE=fates_clm5_scgsr_param_ens_1pft_exp1_210804_multiinst_100inst_v1
#SETUP_CASE=fates_clm5_scgsr_param_ens_2pfts_exp1_210804_multiinst_100inst_v1
SETUP_CASE=fates_clm5_scgsr_multiinst_wrf_2pft_fire_sfmode2_dry3_001
#SETUP_CASE=fates_clm5_scgsr_multiinst_wrf_2pft_002

CASE_NAME=${SETUP_CASE}_${GITHASH1}_${GITHASH2}

casedir=/glade/work/katiem/FATES_cases/SCGSR_cases/

basedir=$SRCDIR/cime/scripts/

cime_model=cesm
MACH=cheyenne

#COMP=2000_DATM%CRUv7_CLM50%FATES_SICE_SOCN_MOSART_SGLC_SWAV
COMP=I2000Clm50Fates

PROJECT=UBOI0006

ninst=100

cd $basedir

./create_newcase --case ${casedir}${CASE_NAME} --res CLM_USRDAT --compset ${COMP} --project ${PROJECT} --run-unsupported --mach ${MACH} --ninst=$ninst --multi-driver

cd ${casedir}${CASE_NAME}

export CLM_DOMAIN_DIR=/glade/work/katiem/sfcdata
export CLM_SURFDAT_DIR=/glade/work/katiem/sfcdata

export SITE_NAME=Idaho_1pt
export CLM_USRDAT_DOMAIN=domain.lnd.ID_KM_singlept_c191104.nc
export CLM_USRDAT_SURDAT=surfdat_ID_KM_singlept_191104.nc

##modify env_mach_pes file
./xmlchange NTASKS_ATM=1
./xmlchange NTASKS_CPL=1
./xmlchange NTASKS_GLC=1
./xmlchange NTASKS_OCN=1
./xmlchange NTASKS_WAV=1
./xmlchange NTASKS_ICE=1
./xmlchange NTASKS_LND=1
./xmlchange NTASKS_ROF=1
./xmlchange ROOTPE_ATM=0
./xmlchange ROOTPE_CPL=1
./xmlchange ROOTPE_GLC=1
./xmlchange ROOTPE_OCN=1
./xmlchange ROOTPE_WAV=1
./xmlchange ROOTPE_ICE=1
./xmlchange ROOTPE_LND=1
./xmlchange ROOTPE_ROF=1
./xmlchange ROOTPE_ESP=1
./xmlchange NTHRDS_ATM=1
./xmlchange NTHRDS_CPL=1
./xmlchange NTHRDS_GLC=1
./xmlchange NTHRDS_OCN=1
./xmlchange NTHRDS_WAV=1
./xmlchange NTHRDS_ICE=1
./xmlchange NTHRDS_LND=1
./xmlchange NTHRDS_ROF=1
./xmlchange NTHRDS_ESP=1

./case.setup

##modify env_run
./xmlchange STOP_OPTION=nyears
./xmlchange STOP_N=1
./xmlchange REST_OPTION=nyears
./xmlchange RESUBMIT=150
./xmlchange CLM_FORCE_COLDSTART=on

./xmlchange JOB_WALLCLOCK_TIME=03:00:00
./xmlchange JOB_QUEUE=regular

##./xmlchange CONTINUE_RUN=TRUE
##./xmlchange DEBUG=FALSE

./xmlchange RUN_STARTDATE='0001-01-01'

./xmlchange DATM_MODE=CLMGSWP3v1
./xmlchange DATM_CLMNCEP_YR_ALIGN=1988
./xmlchange DATM_CLMNCEP_YR_START=1988
./xmlchange DATM_CLMNCEP_YR_END=2015

./xmlchange MOSART_MODE=NULL
./xmlchange ATM_DOMAIN_FILE=${CLM_USRDAT_DOMAIN}
./xmlchange ATM_DOMAIN_PATH=${CLM_DOMAIN_DIR}
./xmlchange LND_DOMAIN_FILE=${CLM_USRDAT_DOMAIN}
./xmlchange LND_DOMAIN_PATH=${CLM_DOMAIN_DIR}
./xmlchange CLM_USRDAT_NAME=${SITE_NAME}
./xmlchange CALENDAR=GREGORIAN

# Update the parameter file here.
for x  in `seq 1 1 $ninst`; do
    expstr=$(printf %04d $x)
    echo $expstr
    cat > user_nl_clm_$expstr <<EOF
fsurdat = '${CLM_SURFDAT_DIR}/${CLM_USRDAT_SURDAT}'
fates_paramfile = '/glade/work/katiem/FATES_data/SCGSR_2021/2pft_100ens_fire/param_file_2PFT_exp2_${expstr}_c211006_dry3.nc'

hist_fincl1 =
'M1_SCPF','M2_SCPF','M3_SCPF','M4_SCPF','M5_SCPF','M6_SCPF','MORTALITY_CANOPY_SCPF','MORTALITY_UNDERSTORY_SCPF','Fire_Closs','PATCH_AREA_BY_AGE','CANOPY_AREA_BY_AGE','BIOMASS_BY_AGE',\
'PFTbiomass','PFTcanopycrownarea','PFTcrownarea','DDBH_CANOPY_SCPF','DDBH_UNDERSTORY_SCPF','NPLANT_CANOPY_SCPF','NPLANT_UNDERSTORY_SCPF','BSTOR_CANOPY_SCPF','BSTOR_UNDERSTORY_SCPF',\
'CWD_AG_CWDSC','NPLANT_SCAG','NPLANT_SCPF','DDBH_SCPF','BA_SCPF','RECRUITMENT',\
'CAMBIALFIREMORT_SCPF','CROWNFIREMORT_SCPF'

hist_mfilt = 12

fates_parteh_mode=1
use_fates=.true.
fates_spitfire_mode=2

EOF

 cat >> user_nl_datm_$expstr <<EOF

EOF
done

# I need something like this to properly copy over the user_datm.steams* files.
for x  in `seq 1 1 $ninst`; do
    expstr=$(printf %04d $x)
    echo $expstr

    cp /glade/work/katiem/FATES_data/ID/singlept/WRF/user_datm.streams.txt.CLMGSWP3v1.Precip /${casedir}${CASE_NAME}/user_datm.streams.txt.CLMGSWP3v1.Precip_${expstr}
    cp /glade/work/katiem/FATES_data/ID/singlept/WRF/user_datm.streams.txt.CLMGSWP3v1.Solar /${casedir}${CASE_NAME}/user_datm.streams.txt.CLMGSWP3v1.Solar_${expstr}
    cp /glade/work/katiem/FATES_data/ID/singlept/WRF/user_datm.streams.txt.CLMGSWP3v1.TPQW /${casedir}${CASE_NAME}/user_datm.streams.txt.CLMGSWP3v1.TPQW_${expstr}

done


qcmd -A UBOI0006  -- ./case.build
./case.submit








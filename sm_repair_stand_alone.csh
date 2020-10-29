#!/bin/csh


echo -----------------------------------
set msg = "Begin  sm_repair_stand_alone.csh"
echo ${msg} 
#PAUSE ${msg}
echo -----------------------------------

################
# for debugging
#set echo
set verbose
################

set job_name = $JOB
set step_name = $STEP

echo -----------------------------------
set msg = "Begin Flashed pads"
echo ${msg} 
#PAUSE ${msg}
echo -----------------------------------

########## Make Flashed pads, if masks exist ##########

COM affected_layer,mode=all,affected=no
COM clear_highlight
COM sel_clear_feat
COM clear_layers

########### Get both masks
# gather the names of the soldermask layers
COM affected_filter,filter=(type=solder_mask&context=board)
COM get_affect_layer
set affected_layers = `echo $COMANS`
if ( `echo ${affected_layers}` != "" ) then
  #PAUSE  ${affected_layers} affected.  Soldermask repair will be performed on these layers
endif
set soldermask_layers = "$affected_layers"  
COM affected_layer,mode=all,affected=no
###########
foreach layer ( $soldermask_layers  )
   #PAUSE  layer $layer is a mask layer
end

########### Get top soldermask
COM affected_filter,filter=(type=solder_mask&context=board&side=top)
COM get_affect_layer
set affected_layers = `echo $COMANS`
if ( `echo ${affected_layers}` != "" ) then
  #PAUSE  ${affected_layers} is top_sm 
endif 
set top_sm = ${affected_layers}
COM affected_layer,mode=all,affected=no
###########
########### Get bottom soldermask
COM affected_filter,filter=(type=solder_mask&context=board&side=bottom)
COM get_affect_layer
set affected_layers = `echo $COMANS`
if ( `echo ${affected_layers}` != "" ) then
  #PAUSE  ${affected_layers} is bot_sm 
endif 
set bot_sm = ${affected_layers}
COM affected_layer,mode=all,affected=no
###########


COM affected_filter,filter=(type=signal|power_ground|mixed&context=board&side=top|bottom)


########### Get both outers
# gather the names of the outer layers
COM affected_filter,filter=(type=signal|power_ground|mixed&context=board&side=top|bottom)
COM get_affect_layer
set affected_layers = `echo $COMANS`
if ( `echo ${affected_layers}` != "" ) then
  #PAUSE  ${affected_layers} affected.  Flashed pads will be performed on these layers
endif
set outer_layers = "$affected_layers" 
COM affected_layer,mode=all,affected=no
###########
foreach layer ( $outer_layers  )
   #PAUSE  layer $layer is an outer layer
end

########### Get top copper
COM affected_filter,filter=(type=signal|power_ground|mixed&context=board&side=top)
COM get_affect_layer
set affected_layers = `echo $COMANS`
if ( `echo ${affected_layers}` != "" ) then
  #PAUSE  ${affected_layers} is top_cu 
endif 
set top_cu = ${affected_layers}
COM affected_layer,mode=all,affected=no
###########
########### Get bottom copper
COM affected_filter,filter=(type=signal|power_ground|mixed&context=board&side=bottom)
COM get_affect_layer
set affected_layers = `echo $COMANS`
if ( `echo ${affected_layers}` != "" ) then
  #PAUSE  ${affected_layers} is bot_cu 
endif 
set bot_cu = ${affected_layers}
COM affected_layer,mode=all,affected=no
###########
#############
if ( ${top_sm} != "" ) then
  if ( ${top_cu} != "" ) then
     COM display_layer,name=${top_cu},display=yes,number=1
     COM work_layer,name=${top_cu}
     COM filter_set,filter_name=popup,update_popup=no,feat_types=pad
     COM filter_set,filter_name=popup,update_popup=no,polarity=positive
     COM filter_area_strt
     COM filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,\
       inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,\
       min_angle=0,max_angle=0
     set flashes_found = $COMANS
     COM filter_reset,filter_name=popup
     if ( $flashes_found > 0 ) then
       PAUSE Check that all ${top_cu} pads flashed
     else
       COM clear_highlight
       COM sel_clear_feat
       PAUSE No pads flashed on ${top_cu}, convert pads
     endif
     COM filter_reset,filter_name=popup
     COM clear_highlight
     COM sel_clear_feat
     COM affected_layer,mode=all,affected=no
     COM clear_layers 
   endif  
endif
#############
#############
if ( ${bot_sm} != "" ) then
  if ( ${bot_cu} != "" ) then
      COM display_layer,name=${bot_cu},display=yes,number=1
      COM work_layer,name=${bot_cu}
      COM filter_set,filter_name=popup,update_popup=no,feat_types=pad
      COM filter_set,filter_name=popup,update_popup=no,polarity=positive
      COM filter_area_strt
      COM filter_area_end,layer=,filter_name=popup,operation=select,area_type=none,\
      inside_area=no,intersect_area=no,lines_only=no,ovals_only=no,min_len=0,max_len=0,\
      min_angle=0,max_angle=0
      COM filter_reset,filter_name=popup
      PAUSE Check that all ${bot_cu} pads flashed
      COM filter_reset,filter_name=popup
      COM clear_highlight
      COM sel_clear_feat
      COM affected_layer,mode=all,affected=no
      COM clear_layers
   endif
endif
#############
########## End Flashed pads ##########
#PAUSE End Flashed pads




#################### Soldermask Repair ##############################
########## Soldermask Repair ##########
# clear everything
COM affected_layer,mode=all,affected=no
COM clear_highlight
COM sel_clear_feat
COM clear_layers
  
  
if ( ${top_sm} != ""  || ${bot_sm} != ""  ) then


   set gui_result = 1
  if ($gui_result == 1) then 
    ####################  $run_sm_repair == 1  ##########
    #The new visual SM check should go here
   
    ########## Visual SM comparison #########
    # this code runs soldermask repair, then does a layer to layer  compare of the originals 
    # against the finished layers and highlights any changes that are more than 5 mils
    # and then displays them for a visual inspection by the user.
    
    #PAUSE Starting Soldermask Repair: visual compare vs Originals. Continue
  		   
      # affect both
      set soldermask = ()
      if ( ${top_sm} != "" ) then
         COM affected_layer,name=${top_sm},mode=single,affected=yes
         #PAUSE ${top_sm} exists, so making a copy ${top_sm}.orig
         COM copy_layer,source_job=${job_name} ,source_step=${step_name},source_layer=${top_sm},dest=layer_name,\
         dest_layer=${top_sm}.orig,mode=replace,invert=no 
         set soldermask = ("${top_sm}")
      endif 
      if ( ${bot_sm} != "" ) then    
        COM affected_layer,name=${bot_sm} ,mode=single,affected=yes
        #PAUSE ${bot_sm}  exists, so making a copy ${bot_sm}.orig
        COM copy_layer,source_job=${job_name} ,source_step=${step_name},source_layer=${bot_sm} ,dest=layer_name,\
        dest_layer=${bot_sm}.orig,mode=replace,invert=no 
        set soldermask = ($soldermask "${bot_sm}")
      endif
    
    
    # make a copy of each SM layer as original, before running soldermask repair
    #PAUSE test about to run SM repair on layer(s) $soldermask
    #foreach _file ( $_files )
    #end
    #COM copy_layer,source_job=61449+fix.valorcam_ee06,source_step=quote+1,source_layer=m2,dest=layer_name,\
    #dest_layer=m2.orig,mode=replace,invert=no 
    
    ####    The fix_sm_repair code placed in here
    #set top_mask_fixed = "no"
    #set bottom_mask_fixed = "no"
    #set mask_name = "${top_sm}"
    #set copper_name = "${top_cu}"
    COM chklist_single,action=frontline_dfm_smo,show=yes
    set sm_settings = tempe
    if ( $sm_settings == "tempe" ) then
       # tempe
       COM chklist_cupd,chklist=frontline_dfm_smo,nact=1,\
       params=(\
       (pp_layer=.type=signal|mixed&side=top|bottom)\
       (pp_min_clear=2.0)(pp_opt_clear=2.0)\
       (pp_min_cover=5)(pp_opt_cover=5)\
       (pp_min_bridge=5)(pp_opt_bridge=5)\
       (pp_selected=All)(pp_use_mask=Yes)\
       (pp_use_shave=No)\
       (pp_fix_coverage=PTH;Via;NPTH;SMD)\
       (pp_fix_bridge=PTH;Via;NPTH;SMD)\
       (pp_clear_coverage_comp=100)\
       (pp_clear_bridge_comp=100)\
       (pp_smd_pth_bridge_comp=50)\
       (pp_smd_via_bridge_comp=50)\
       (pp_smd_npth_bridge_comp=50)\
       (pp_partial=)(pp_ignore_types=)(pp_ignore_attrs=)),\
       mode=regular     
    else  
       # Aurora
       COM chklist_cupd,chklist=frontline_dfm_smo,nact=1,\
       params=(\
       (pp_layer=.type=signal|mixed&side=top|bottom)\
       (pp_min_clear=2.6)(pp_opt_clear=2.6)\
       (pp_min_cover=0)(pp_opt_cover=3)\
       (pp_min_bridge=0)(pp_opt_bridge=3)\
       (pp_selected=All)(pp_use_mask=Yes)\
       (pp_use_shave=No)\
       (pp_fix_coverage=PTH;Via;NPTH;SMD)\
       (pp_fix_bridge=PTH;Via;NPTH;SMD)\
       (pp_clear_coverage_comp=100)\
       (pp_clear_bridge_comp=100)\
       (pp_smd_pth_bridge_comp=50)\
       (pp_smd_via_bridge_comp=50)\
       (pp_smd_npth_bridge_comp=50)\
       (pp_partial=)(pp_ignore_types=)(pp_ignore_attrs=)),\
       mode=regular
    endif


 
    
    COM chklist_run,chklist=frontline_dfm_smo,nact=1,area=profile
    COM chklist_close,chklist=frontline_dfm_smo,mode=hide
    ####    
    
    
    #PAUSE after frontline_dfm_smo on ${top_sm} ${top_cu}
    
    
    
    # compare  
    echo PAUSE about to compare modified masks layers with originals
    foreach smlayer ( $soldermask )
        COM affected_layer,name=$smlayer,mode=all,affected=no
        COM clear_layers
        echo PAUSE TESTING: Right before the compare, over reduce a mask on the revised ${smlayer}--- edit resize global -25
       
        # tolerance was set to tol=5, but this is pretty tight, changing it to 6
        COM compare_layers,layer1=${smlayer},job2=${job_name},step2=${step_name},layer2=${smlayer}.orig,layer2_ext=,\
            tol=6,area=profile,consider_sr=yes,ignore_attr=,map_layer=${smlayer}.cmp,map_layer_res=200
        COM zoom_home
        #PAUSE mx.cmp should now be created.
        
         
        #PAUSE if the ${smlayer}.cmp contains any r0 pads or r0 lines then there are open windows and excessive mods
        # change for Tempe environment:
        # Aurora writes to local hard drive c:/tmp, but Tempe's Unix environment cannot
        # writing to a UNIX pathed folder for testing
        set tmp_dir_rp = /usr/genesis/tmp 
       #COM info, out_file=C:/tmp/opt_mask.txt,args=  -t layer -e ${job_name}/${step_name}/${smlayer}.cmp -m script -d SYMS_HIST
        COM info, out_file=${tmp_dir_rp}/opt_mask.txt,args=  -t layer -e ${job_name}/${step_name}/${smlayer}.cmp -m script -d SYMS_HIST
       #source C:/tmp/opt_mask.txt
	source ${tmp_dir_rp}/opt_mask.txt
	# r0 exists
	#set gSYMS_HISTsymbol = ('s200' 'r0')
	#set gSYMS_HISTline   = ('637'  '12')
	#set gSYMS_HISTpad    = ('0'    '3' )
	#set gSYMS_HISTarc    = ('0'    '0' )
        
        # r0 DNE 
        #set gSYMS_HISTsymbol = ('s200')
	#set gSYMS_HISTline   = ('640' )
	#set gSYMS_HISTpad    = ('0'   )
        #set gSYMS_HISTarc    = ('0'   )
        
        set r0_detected = 0
        # loop through gSYMS_HISTsymbol and if one is r0, set r0_detected = 1
        foreach symbol ( $gSYMS_HISTsymbol ) 
           if ( $symbol == "r0" ) then
              #PAUSE r0 symbol detected $symbol 
              set r0_detected = 1
           else
              #PAUSE symbol $symbol is NOT r0
           endif
        end
        

        # note: Non-plated holes on production can cause false alarms
        # if customer mask reliefs are oversized, we may reduce them, this may prevent mask slivers below 3 mils
        


        if ( $r0_detected == 1 ) then
           #PAUSE Zero mil features detected on ${smlayer}.cmp
           ############
           COM display_layer,name=${smlayer},display=yes,number=1
           COM display_layer,name=${smlayer}.orig,display=yes,number=2
           COM display_layer,name=${smlayer}.cmp,display=yes,number=3
           #PAUSE For $smlayer , please check the original soldermask against the modified mask, any open boxes in the .cmp layer should be reviewed.
           PAUSE WARNING: EXCESSIVE SOLDERMASK CHANGES: Review any OPEN BOXES in the $smlayer.cmp layer, please compare $smlayer to $smlayer.orig, and repair
           ############
           
           ###### Send an email to CAM supervisors if a SMrepair ERROR occured ######
           
           set error_code = Excessive_SMRepair_modifications_detected
           set recipient_list = "rpowers@4pcb.com"
           #source ${GENESIS_DIR}/sys/scripts/email_SMRepair_Mod_error.csh           
           
           ############
        else
           #PAUSE SUCCESS: After SMRepair, No Zero mil features were detected ${smlayer}.cmp
        endif
        
        
        COM delete_layer,layer=${smlayer}.orig
        COM delete_layer,layer=${smlayer}.cmp
    end
    
    COM affected_layer,name=$smlayer,mode=all,affected=no
    COM clear_layers
    
    
    #COM affected_layer,name=,mode=all,affected=no
    #exit 0
    
    #PAUSE Test code: END: Soldermask Repair visual Compare   
    ####################    $run_sm_repair == 1    ######################### 
    #source $GENESIS_DIR/sys/scripts/fix_sm_repair.csh
  endif  #  $run_sm_repair == 1  
endif    #  $m2_exists =~ "yes" || $m1_exists =~ "yes" 
#-----------Replace end---------------------------
########## Soldermask Repair end ##########

PAUSE Soldermask Repair complete 
#still good




echo -----------------------------------
echo End   sm_repair_stand_alone.csh
echo -----------------------------------

exit 0
exit 1








































#PAUSE check c-tony-1, already corrupted with older set of files.
# for polarity check it would be good to turn on silk layers 
# for board outline, also silk and top copper

########## Turn on some TOPSIDE layers  #################
# turn l1, s1 and m1 if they exist
  ####################
  #LAYER_EXISTS ${job_name} ${step_name} l1
  set text_layer = l1
  COM info, out_file=c:/tmp/exists.dat, write_mode=append,args=  -t layer -e ${job_name}/${step_name}/${text_layer} -m script -d EXISTS
  source c:/tmp/exists.dat
  rm c:/tmp/exists.dat
  ####################
  if ( $gEXISTS == "yes" ) then
     COM display_layer,name=l1,display=yes,number=1
     # turn on s1 if it exists
     ####################
     #LAYER_EXISTS ${job_name} ${step_name} s1
     set text_layer = s1
     COM info, out_file=c:/tmp/exists.dat, write_mode=append,args=  -t layer -e ${job_name}/${step_name}/${text_layer} -m script -d EXISTS
     source c:/tmp/exists.dat
     rm c:/tmp/exists.dat
     ####################    
     if ( $gEXISTS == "yes" ) then
        COM display_layer,name=s1,display=yes,number=2
        ####################
        #LAYER_EXISTS ${job_name} ${step_name} m1
        set text_layer = m1
        COM info, out_file=c:/tmp/exists.dat, write_mode=append,args=  -t layer -e ${job_name}/${step_name}/${text_layer} -m script -d EXISTS
        source c:/tmp/exists.dat
        rm c:/tmp/exists.dat
        ####################         
        if ( $gEXISTS == "yes" ) then
	   COM display_layer,name=m1,display=yes,number=3
        endif
     endif 
  else  
     LAYER_EXISTS ${job_name} ${step_name} lb
     if ( $gEXISTS == "yes" ) then
        COM display_layer,name=lb,display=yes,number=1
        LAYER_EXISTS ${job_name} ${step_name} s2
        if ( $gEXISTS == "yes" ) then
	   COM display_layer,name=s2,display=yes,number=2
	   LAYER_EXISTS ${job_name} ${step_name} m2
           if ( $gEXISTS == "yes" ) then
	      COM display_layer,name=m2,display=yes,number=3
           endif   
        endif 
     endif
  endif
#---- if no s1 turn on s2 and if no l1 turn on lb
  
COM zoom_home  
 
PAUSE  REVIEW THE TOPSIDE LAYER POLARITY : Check for mirrored files, look for wrong reading text


#########################################################









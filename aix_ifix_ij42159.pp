#
#-------------------------------------------------------------------------------
#
#  From Advisory.asc:
#
#    For NFS kernel extension:
#
#    AIX Level APAR     Availability  SP        KEY         PRODUCT(S)
#    -----------------------------------------------------------------
#    7.1.5     IJ43072  **            SP11      key_w_apar  NFS
#    7.2.5     IJ42159  **            SP06      key_w_apar  NFS
#    7.3.0     IJ43468  **            SP03      key_w_apar  NFS
#
#    VIOS Level APAR    Availability  SP        KEY         PRODUCT(S)
#    -----------------------------------------------------------------
#    3.1.2      IJ43674 **            3.1.2.50  key_w_apar  NFS
#    3.1.3      IJ42159 **            3.1.3.30  key_w_apar  NFS
#
#    For NFS kernel extension:
#
#    AIX Level  Interim Fix (*.Z)         KEY        PRODUCT(S)
#    ----------------------------------------------------------
#    7.1.5.8    IJ43072s8a.221110.epkg.Z  key_w_fix  NFS
#    7.1.5.9    IJ43072sAa.221024.epkg.Z  key_w_fix  NFS
#    7.1.5.10   IJ43072sAa.221024.epkg.Z  key_w_fix  NFS
#    7.2.5.2    IJ43674s2b.221027.epkg.Z  key_w_fix  NFS
#    7.2.5.3    IJ42159s3a.221025.epkg.Z  key_w_fix  NFS
#    7.2.5.3    IJ42159s3b.221213.epkg.Z  key_w_fix  NFS
#    7.2.5.4    IJ42159s4a.221017.epkg.Z  key_w_fix  NFS
#    7.3.0.1    IJ43468s1a.221025.epkg.Z  key_w_fix  NFS
#    7.3.0.2    IJ43468s2a.221017.epkg.Z  key_w_fix  NFS
#
#    Please note that the above table refers to AIX TL/SP level as
#    opposed to fileset level, i.e., 7.2.5.4 is AIX 7200-05-04.
#
#    NOTE:  Multiple iFixes are provided for AIX 7200-05-03.
#    IJ42159s3a is for AIX 7200-05-03 with bos.adt.include fileset level 7.2.5.102.
#    IJ42159s3b is for AIX 7200-05-03 with bos.adt.include fileset level 7.2.5.101.
#
#    VIOS Level  Interim Fix (*.Z)         KEY        PRODUCT(S)
#    -----------------------------------------------------------
#    3.1.2.21    IJ43674s2b.221027.epkg.Z  key_w_fix  NFS
#    3.1.2.30    IJ43674s2c.221213.epkg.Z  key_w_fix  NFS
#    3.1.2.40    IJ43674s2c.221213.epkg.Z  key_w_fix  NFS
#    3.1.3.10    IJ42159s3b.221213.epkg.Z  key_w_fix  NFS
#    3.1.3.14    IJ42159s3a.221025.epkg.Z  key_w_fix  NFS
#    3.1.3.21    IJ42159s4a.221017.epkg.Z  key_w_fix  NFS
#
#-------------------------------------------------------------------------------
#
class aix_ifix_ij42159 {

    #  Make sure we can get to the ::staging module (deprecated ?)
    include ::staging

    #  This only applies to AIX and VIOS 
    if ($::facts['osfamily'] == 'AIX') {

        #  Set the ifix ID up here to be used later in various names
        $ifixName = 'IJ42159'

        #  Make sure we create/manage the ifix staging directory
        require aix_file_opt_ifixes

        #
        #  For now, we're skipping anything that reads as a VIO server.
        #  We have no matching versions of this ifix / VIOS level installed.
        #
        unless ($::facts['aix_vios']['is_vios']) {

            #
            #  Friggin' IBM...  The ifix ID that we find and capture in the fact has the
            #  suffix allready applied.
            #
            if ($::facts['kernelrelease'] == '7200-05-03-2148') {
                $ifixSuffix = 's3a'
                $ifixBuildDate = '221025'
            }
            else {
                if ($::facts['kernelrelease'] == '7200-05-04-2220') {
                    $ifixSuffix = 's4a'
                    $ifixBuildDate = '221017'
                }
                else {
                    $ifixSuffix = 'unknown'
                    $ifixBuildDate = 'unknown'
                }
            }

        }

        #
        #  This one applies equally to AIX and VIOS in our environment, so deal with VIOS as well.
        #
        else {
            if ($::facts['aix_vios']['version'] == '3.1.3.14') {
                $ifixSuffix = 's3a'
                $ifixBuildDate = '221025'
            }
            else {
                $ifixSuffix = 'unknown'
                $ifixBuildDate = 'unknown'
            }
        }

        #================================================================================
        #  Re-factor this code out of the AIX-only branch, since it applies to both.
        #================================================================================

        #  If we set our $ifixSuffix and $ifixBuildDate, we'll continue
        if (($ifixSuffix != 'unknown') and ($ifixBuildDate != 'unknown')) {

            #  Add the name and suffix to make something we can find in the fact
            $ifixFullName = "${ifixName}${ifixSuffix}"

            #  Don't bother with this if it's already showing up installed
            unless ($ifixFullName in $::facts['aix_ifix']['hash'].keys) {
 
                #  Build up the complete name of the ifix staging source and target
                $ifixStagingSource = "puppet:///modules/aix_ifix_ij42159/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"
                $ifixStagingTarget = "/opt/ifixes/${ifixName}${ifixSuffix}.${ifixBuildDate}.epkg.Z"

                #  Stage it
                staging::file { "$ifixStagingSource" :
                    source  => "$ifixStagingSource",
                    target  => "$ifixStagingTarget",
                    before  => Exec["emgr-install-${ifixName}"],
                }

                #  GAG!  Use an exec resource to install it, since we have no other option yet
                exec { "emgr-install-${ifixName}":
                    path     => '/bin:/sbin:/usr/bin:/usr/sbin:/etc',
                    command  => "/usr/sbin/emgr -e $ifixStagingTarget",
                    unless   => "/usr/sbin/emgr -l -L $ifixFullName",
                }

                #  Explicitly define the dependency relationships between our resources
                File['/opt/ifixes']->Staging::File["$ifixStagingSource"]->Exec["emgr-install-${ifixName}"]

            }

        }

    }

}

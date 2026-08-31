<?php declare(strict_types=1);

namespace App\DependencyInjection\Compiler;

use App\Twig\LocaleAwareLoader;
use Symfony\Component\DependencyInjection\Compiler\CompilerPassInterface;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Reference;

class LocaleAwareTwigLoaderPass implements CompilerPassInterface
{
    public function process(ContainerBuilder $container): void
    {
        if (!$container->hasDefinition('twig.loader.native_filesystem')) {
            return;
        }

        $loader = $container->getDefinition('twig.loader.native_filesystem');
        $loader->setClass(LocaleAwareLoader::class);
        $loader->setArguments([
            new Reference('request_stack'),
            [],
            '%kernel.project_dir%',
        ]);
    }
}
